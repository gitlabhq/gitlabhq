# frozen_string_literal: true

require 'toml-rb'
require 're2'
require 'logger'
require 'timeout'
require 'parallel'

module Gitlab
  module SecretDetection
    # Scan is responsible for running Secret Detection scan operation
    class Scan
      # RulesetParseError is thrown when the code fails to parse the
      # ruleset file from the given path
      RulesetParseError = Class.new(StandardError)

      # RulesetCompilationError is thrown when the code fails to compile
      # the predefined rulesets
      RulesetCompilationError = Class.new(StandardError)

      # default time limit(in seconds) for running the scan operation per invocation
      DEFAULT_SCAN_TIMEOUT_SECS = 60
      # default time limit(in seconds) for running the scan operation on a single blob
      DEFAULT_BLOB_TIMEOUT_SECS = 5
      # file path where the secrets ruleset file is located
      RULESET_FILE_PATH = File.expand_path('../../gitleaks.toml', __dir__)
      # Max no of child processes to spawn per request
      # ref: https://gitlab.com/gitlab-org/gitlab/-/issues/430160
      MAX_PROCS_PER_REQUEST = 5
      # Minimum cumulative size of the blobs required to spawn and
      # run the scan within a new subprocess.
      MIN_CHUNK_SIZE_PER_PROC_BYTES = 2_097_152 # 2MiB
      # Whether to run scan in subprocesses or not. Default is true.
      RUN_IN_SUBPROCESS = true

      # Initializes the instance with logger along with following operations:
      # 1. Parse ruleset for the given +ruleset_path+(default: +RULESET_FILE_PATH+). Raises +RulesetParseError+
      # in case the operation fails.
      # 2. Extract keywords from the parsed ruleset to use it for matching keywords before regex operation.
      # 3. Build and Compile rule regex patterns obtained from the ruleset. Raises +RulesetCompilationError+
      # in case the compilation fails.
      def initialize(logger: Logger.new($stdout), ruleset_path: RULESET_FILE_PATH)
        @logger = logger
        @rules = parse_ruleset(ruleset_path)
        @keywords = create_keywords(rules)
        @pattern_matcher = build_pattern_matcher(rules)
      end

      # Runs Secret Detection scan on the list of given blobs. Both the total scan duration and
      # the duration for each blob is time bound via +timeout+ and +blob_timeout+ respectively.
      #
      # +blobs+:: Array of blobs with each blob to have `id` and `data` properties.
      # +timeout+:: No of seconds(accepts floating point for smaller time values) to limit the total scan duration
      # +blob_timeout+:: No of seconds(accepts floating point for smaller time values) to limit
      #                  the scan duration on each blob
      # +subprocess+:: If passed true, the scan is performed within subprocess instead of main process.
      #           To avoid over-consuming memory by running scan on multiple large blobs within a single subprocess,
      #           it instead groups the blobs into smaller array where each array contains blobs with cumulative size of
      #           +MIN_CHUNK_SIZE_PER_PROC_BYTES+ bytes and each group runs in a separate sub-process. Default value
      #           is true.
      #
      # NOTE:
      # Running the scan in fork mode primarily focuses on reducing the memory consumption of the scan by
      # offloading regex operations on large blobs to sub-processes. However, it does not assure the improvement
      # in the overall latency of the scan, specifically in the case of smaller blob sizes, where the overhead of
      # forking a new process adds to the overall latency of the scan instead. More reference on Subprocess-based
      # execution is found here: https://gitlab.com/gitlab-org/gitlab/-/issues/430160.
      #
      # Returns an instance of SecretDetection::Response by following below structure:
      # {
      #     status: One of the SecretDetection::Status values
      #     results: [SecretDetection::Finding]
      # }
      #
      def secrets_scan(
        blobs,
        timeout: DEFAULT_SCAN_TIMEOUT_SECS,
        blob_timeout: DEFAULT_BLOB_TIMEOUT_SECS,
        subprocess: RUN_IN_SUBPROCESS
      )
        return SecretDetection::Response.new(SecretDetection::Status::INPUT_ERROR) unless validate_scan_input(blobs)

        Timeout.timeout(timeout) do
          matched_blobs = filter_by_keywords(blobs)

          next SecretDetection::Response.new(SecretDetection::Status::NOT_FOUND) if matched_blobs.empty?

          secrets = if subprocess
                      run_scan_within_subprocess(matched_blobs, blob_timeout)
                    else
                      run_scan(matched_blobs, blob_timeout)
                    end

          scan_status = overall_scan_status(secrets)

          SecretDetection::Response.new(scan_status, secrets)
        end
      rescue Timeout::Error => e
        logger.error "Secret detection operation timed out: #{e}"

        SecretDetection::Response.new(SecretDetection::Status::SCAN_TIMEOUT)
      end

      private

      attr_reader :logger, :rules, :keywords, :pattern_matcher

      # parses given ruleset file and returns the parsed rules
      def parse_ruleset(ruleset_file_path)
        rules_data = TomlRB.load_file(ruleset_file_path)
        rules_data['rules']
      rescue StandardError => e
        logger.error "Failed to parse secret detection ruleset from '#{ruleset_file_path}' path: #{e}"

        raise RulesetParseError
      end

      # builds RE2::Set pattern matcher for the given rules
      def build_pattern_matcher(rules)
        matcher = RE2::Set.new

        rules.each do |rule|
          matcher.add(rule["regex"])
        end

        unless matcher.compile
          logger.error "Failed to compile secret detection rulesets in RE::Set"

          raise RulesetCompilationError
        end

        matcher
      end

      # creates and returns the unique set of rule matching keywords
      def create_keywords(rules)
        secrets_keywords = []

        rules.each do |rule|
          secrets_keywords << rule["keywords"]
        end

        secrets_keywords.flatten.compact.to_set
      end

      # returns only those blobs that contain at least one of the keywords
      # from the keywords list
      def filter_by_keywords(blobs)
        matched_blobs = []

        blobs.each do |blob|
          matched_blobs << blob if keywords.any? { |keyword| blob.data.include?(keyword) }
        end

        matched_blobs.freeze
      end

      def run_scan(blobs, blob_timeout)
        found_secrets = blobs.flat_map do |blob|
          Timeout.timeout(blob_timeout) do
            find_secrets(blob)
          end
        rescue Timeout::Error => e
          logger.error "Secret Detection scan timed out on the blob(id:#{blob.id}): #{e}"
          SecretDetection::Finding.new(blob.id,
            SecretDetection::Status::PAYLOAD_TIMEOUT)
        end

        found_secrets.freeze
      end

      def run_scan_within_subprocess(blobs, blob_timeout)
        blob_sizes = blobs.map(&:size)
        grouped_blob_indicies = group_by_chunk_size(blob_sizes)

        grouped_blobs = grouped_blob_indicies.map { |idx_arr| idx_arr.map { |i| blobs[i] } }

        found_secrets = Parallel.flat_map(
          grouped_blobs,
          in_processes: MAX_PROCS_PER_REQUEST,
          isolation: true # do not reuse sub-processes
        ) do |grouped_blob|
          grouped_blob.flat_map do |blob|
            Timeout.timeout(blob_timeout) do
              find_secrets(blob)
            end
          rescue Timeout::Error => e
            logger.error "Secret Detection scan timed out on the blob(id:#{blob.id}): #{e}"
            SecretDetection::Finding.new(blob.id,
              SecretDetection::Status::PAYLOAD_TIMEOUT)
          end
        end

        found_secrets.freeze
      end

      # finds secrets in the given blob with a timeout circuit breaker
      def find_secrets(blob)
        secrets = []

        blob.data.each_line.with_index do |line, index|
          patterns = pattern_matcher.match(line, exception: false)

          next unless patterns.any?

          line_number = index + 1
          patterns.each do |pattern|
            type = rules[pattern]["id"]
            description = rules[pattern]["description"]

            secrets << SecretDetection::Finding.new(
              blob.id,
              SecretDetection::Status::FOUND,
              line_number,
              type,
              description
            )
          end
        end

        secrets
      rescue StandardError => e
        logger.error "Secret Detection scan failed on the blob(id:#{blob.id}): #{e}"

        SecretDetection::Finding.new(blob.id, SecretDetection::Status::SCAN_ERROR)
      end

      def validate_scan_input(blobs)
        return false if blobs.nil? || !blobs.instance_of?(Array)

        blobs.all? do |blob|
          next false unless blob.respond_to?(:id) || blob.respond_to?(:data)

          blob.data.freeze # freeze blobs to avoid additional object allocations on strings
        end
      end

      def overall_scan_status(found_secrets)
        return SecretDetection::Status::NOT_FOUND if found_secrets.empty?

        timed_out_blobs = found_secrets.count { |el| el.status == SecretDetection::Status::PAYLOAD_TIMEOUT }

        case timed_out_blobs
        when 0
          SecretDetection::Status::FOUND
        when found_secrets.length
          SecretDetection::Status::SCAN_TIMEOUT
        else
          SecretDetection::Status::FOUND_WITH_ERRORS
        end
      end

      # This method accepts an array of blob sizes(in bytes) and groups them into an array
      # of arrays structure where each element is the group of indicies of the input
      # array whose cumulative blob sizes has at least +MIN_CHUNK_SIZE_PER_PROC_BYTES+
      def group_by_chunk_size(blob_size_arr)
        cumulative_size = 0
        chunk_indexes = []
        chunk_idx_start = 0

        blob_size_arr.each_with_index do |size, index|
          cumulative_size += size
          next unless cumulative_size >= MIN_CHUNK_SIZE_PER_PROC_BYTES

          chunk_indexes << (chunk_idx_start..index).to_a

          chunk_idx_start = index + 1
          cumulative_size = 0
        end

        if cumulative_size.positive? && (chunk_idx_start < blob_size_arr.length)
          chunk_indexes << if chunk_idx_start == blob_size_arr.length - 1
                             [chunk_idx_start]
                           else
                             (chunk_idx_start..blob_size_arr.length - 1).to_a
                           end
        end

        chunk_indexes
      end
    end
  end
end
