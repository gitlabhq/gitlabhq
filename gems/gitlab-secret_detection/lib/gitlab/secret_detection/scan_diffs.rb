# frozen_string_literal: true

require 'toml-rb'
require 're2'
require 'logger'
require 'timeout'
require 'parallel'

module Gitlab
  module SecretDetection
    # Scan is responsible for running Secret Detection scan operation
    class ScanDiffs
      # RulesetParseError is thrown when the code fails to parse the
      # ruleset file from the given path
      RulesetParseError = Class.new(StandardError)

      # RulesetCompilationError is thrown when the code fails to compile
      # the predefined rulesets
      RulesetCompilationError = Class.new(StandardError)

      # default time limit(in seconds) for running the scan operation per invocation
      DEFAULT_SCAN_TIMEOUT_SECS = 60
      # default time limit(in seconds) for running the scan operation on a single diff
      DEFAULT_PAYLOAD_TIMEOUT_SECS = 5
      # file path where the secrets ruleset file is located
      RULESET_FILE_PATH = File.expand_path('../../gitleaks.toml', __dir__)
      # Max no of child processes to spawn per request
      # ref: https://gitlab.com/gitlab-org/gitlab/-/issues/430160
      MAX_PROCS_PER_REQUEST = 5
      # Minimum cumulative size of the diffs required to spawn and
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

      # Runs Secret Detection scan on the list of given diffs. Both the total scan duration and
      # the duration for each diff is time bound via +timeout+ and +payload_timeout+ respectively.
      #
      # +diffs+:: Array of diffs between diff pairs. Each diff has attributes: left_blob_id, right_blob_id,
      #           patch, status, binary, and over_patch_bytes_limit.
      # +timeout+:: No of seconds(accepts floating point for smaller time values) to limit the total scan duration
      # +payload_timeout+:: No of seconds(accepts floating point for smaller time values) to limit
      #                  the scan duration on each diff
      # +subprocess+:: If passed true, the scan is performed within subprocess instead of main process.
      #           To avoid over-consuming memory by running scan on multiple large diffs within a single subprocess,
      #           it instead groups the diffs into smaller array where each array contains diffs with cumulative size of
      #           +MIN_CHUNK_SIZE_PER_PROC_BYTES+ bytes and each group runs in a separate sub-process. Default value
      #           is true.
      # +exclusions+:: A hash containing arrays of exclusions by their type. Types handled here are
      #                `raw_value` and `rule`.
      #
      # NOTE:
      # Running the scan in fork mode primarily focuses on reducing the memory consumption of the scan by
      # offloading regex operations on large diffs to sub-processes. However, it does not assure the improvement
      # in the overall latency of the scan, specifically in the case of smaller diff sizes, where the overhead of
      # forking a new process adds to the overall latency of the scan instead. More reference on Subprocess-based
      # execution is found here: https://gitlab.com/gitlab-org/gitlab/-/issues/430160.
      #
      # Returns an instance of SecretDetection::Response by following below structure:
      # {
      #     status: One of the SecretDetection::Status values
      #     results: [SecretDetection::Finding],
      #     applied_exclusions: [Security::ProjectSecurityExclusion]
      # }
      #
      def secrets_scan(
        diffs,
        timeout: DEFAULT_SCAN_TIMEOUT_SECS,
        payload_timeout: DEFAULT_PAYLOAD_TIMEOUT_SECS,
        subprocess: RUN_IN_SUBPROCESS,
        exclusions: {}
      )

        return SecretDetection::Response.new(SecretDetection::Status::INPUT_ERROR) unless validate_scan_input(diffs)

        Timeout.timeout(timeout) do
          matched_diffs = filter_by_keywords(diffs)

          next SecretDetection::Response.new(SecretDetection::Status::NOT_FOUND) if matched_diffs.empty?

          scan_result =
            if subprocess
              run_scan_within_subprocess(matched_diffs, payload_timeout, exclusions)
            else
              run_scan(matched_diffs, payload_timeout, exclusions)
            end

          scan_status = overall_scan_status(scan_result[:secrets])

          SecretDetection::Response.new(
            scan_status,
            scan_result[:secrets],
            scan_result[:applied_exclusions]
          )
        end
      rescue Timeout::Error => e
        logger.error "Secret detection operation timed out: #{e}"

        SecretDetection::Response.new(SecretDetection::Status::SCAN_TIMEOUT)
      end

      private

      attr_reader :logger, :rules, :keywords, :pattern_matcher, :applied_exclusions

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

      # returns only those diffs that contain at least one of the keywords
      # from the keywords list
      def filter_by_keywords(diffs)
        matched_diffs = []

        diffs.each do |diff|
          matched_diffs << diff if keywords.any? { |keyword| diff.patch.include?(keyword) }
        end

        matched_diffs.freeze
      end

      def run_scan(diffs, payload_timeout, exclusions)
        results = diffs.flat_map do |diff|
          Timeout.timeout(payload_timeout) do
            find_secrets(diff, exclusions)
          end
        rescue Timeout::Error => e
          logger.error "Secret Detection scan timed out on the diff(id:#{diff.right_blob_id}): #{e}"

          # This mimics the structure returned from `find_secrets(...)`.
          {
            secrets: [SecretDetection::Finding.new(diff.right_blob_id, SecretDetection::Status::PAYLOAD_TIMEOUT)],
            applied_exclusions: []
          }
        end

        {
          secrets: results.flat_map { |result| result[:secrets] },
          applied_exclusions: results.flat_map { |result| result[:applied_exclusions] }
        }
      end

      def run_scan_within_subprocess(diffs, payload_timeout, exclusions)
        diff_sizes = diffs.map { |diff| diff.patch.bytesize }

        grouped_diff_indicies = group_by_chunk_size(diff_sizes)
        grouped_diffs = grouped_diff_indicies.map { |idx_arr| idx_arr.map { |i| diffs[i] } }

        results = Parallel.flat_map(
          grouped_diffs,
          in_processes: MAX_PROCS_PER_REQUEST,
          isolation: true # do not reuse sub-processes
        ) do |grouped_diff|
          grouped_diff.map do |diff|
            Timeout.timeout(payload_timeout) do
              find_secrets(diff, exclusions)
            end
          rescue Timeout::Error => e
            logger.error "Secret Detection scan timed out on the diff(id:#{diff.right_blob_id}): #{e}"

            # This mimics the structure returned from `find_secrets(...)`.
            {
              secrets: [SecretDetection::Finding.new(diff.right_blob_id, SecretDetection::Status::PAYLOAD_TIMEOUT)],
              applied_exclusions: []
            }
          end
        end

        {
          secrets: results.flat_map { |result| result[:secrets] },
          applied_exclusions: results.flat_map { |result| result[:applied_exclusions] }
        }
      end

      # finds secrets in the given diff with a timeout circuit breaker
      def find_secrets(diff, exclusions)
        secrets = []
        applied_exclusions = []
        line_number_offset = 0

        # The following section parses a single line in a diff patch.
        #
        # If the line starts with @@, it is the hunk header, used to calculate the line number.
        # If the line starts with +, it is newly added in this diff, and we
        # scan the line for newly added secrets. Also increment line number.
        # If the line starts with -, it is removed in this diff, do not increment line number.
        # If the line starts with \\, it is the no newline marker, do not increment line number.
        # If the line starts with a space character, it is a context line, just increment the line number.
        #
        # A context line that starts with an important character would still be treated
        # like a context line, as shown below:
        # @@ -1,5 +1,5 @@
        #  context line
        # -removed line
        # +added line
        #  @@this context line has a @@ but starts with a space so isnt a header
        #  +this context line has a + but starts with a space so isnt an addition
        #  -this context line has a - but starts with a space so isnt a removal
        diff.patch.each_line do |line|
          exclusions[:raw_value]&.each do |exclusion|
            next unless line.include?(exclusion.value)

            applied_exclusions << exclusion

            line.gsub!(exclusion.value, '') # remove excluded raw value from the line.
          end

          # Parse hunk header for start line
          if line.start_with?("@@")
            hunk_info = line.match(/@@ -\d+(,\d+)? \+(\d+)(,\d+)? @@/)
            start_line = hunk_info[2].to_i
            line_number_offset = start_line - 1
          # Line added in this commit
          elsif line.start_with?('+')
            line_number_offset += 1
            # Remove leading +
            line_content = line[1..]

            patterns = pattern_matcher.match(line_content, exception: false)

            next unless patterns.any?

            patterns.each do |pattern|
              type = rules[pattern]["id"]
              description = rules[pattern]["description"]

              # Check if rule type is excluded and if so, skip this rule and count this as an applied exclusion
              next if applied_rule_exclusion?(type, exclusions[:rule], applied_exclusions)

              secrets << SecretDetection::Finding.new(
                diff.right_blob_id,
                SecretDetection::Status::FOUND,
                line_number_offset,
                type,
                description
              )
            end
          # Line not added in this commit, just increment line number
          elsif line.start_with?(' ')
            line_number_offset += 1
          # Line removed in this commit or no newline marker, do not increment line number
          elsif line.start_with?('-', '\\')
            # No increment
          end
        end

        { secrets:, applied_exclusions: }
      rescue StandardError => e
        logger.error "Secret Detection scan failed on the diff(id:#{diff.right_blob_id}): #{e}"

        {
          secrets: [SecretDetection::Finding.new(diff.right_blob_id, SecretDetection::Status::SCAN_ERROR)],
          applied_exclusions: []
        }
      end

      def applied_rule_exclusion?(type, rule_exclusions, applied_exclusions)
        applied_exclusion = rule_exclusions&.find { |rule_exclusion| rule_exclusion.value == type }
        applied_exclusion && (applied_exclusions << applied_exclusion)
      end

      def validate_scan_input(diffs)
        return false if diffs.nil? || !diffs.instance_of?(Array)

        diffs.each { |diff| diff.patch.freeze }
      end

      def overall_scan_status(found_secrets)
        return SecretDetection::Status::NOT_FOUND if found_secrets.empty?

        timed_out_diffs = found_secrets.count { |el| el.status == SecretDetection::Status::PAYLOAD_TIMEOUT }

        case timed_out_diffs
        when 0
          SecretDetection::Status::FOUND
        when found_secrets.length
          SecretDetection::Status::SCAN_TIMEOUT
        else
          SecretDetection::Status::FOUND_WITH_ERRORS
        end
      end

      # This method accepts an array of diff sizes(in bytes) and groups them into an array
      # of arrays structure where each element is the group of indicies of the input
      # array whose cumulative diff sizes has at least +MIN_CHUNK_SIZE_PER_PROC_BYTES+
      def group_by_chunk_size(diff_size_arr)
        cumulative_size = 0
        chunk_indexes = []
        chunk_idx_start = 0

        diff_size_arr.each_with_index do |size, index|
          cumulative_size += size
          next unless cumulative_size >= MIN_CHUNK_SIZE_PER_PROC_BYTES

          chunk_indexes << (chunk_idx_start..index).to_a

          chunk_idx_start = index + 1
          cumulative_size = 0
        end

        if cumulative_size.positive? && (chunk_idx_start < diff_size_arr.length)
          chunk_indexes << if chunk_idx_start == diff_size_arr.length - 1
                             [chunk_idx_start]
                           else
                             (chunk_idx_start..diff_size_arr.length - 1).to_a
                           end
        end

        chunk_indexes
      end
    end
  end
end
