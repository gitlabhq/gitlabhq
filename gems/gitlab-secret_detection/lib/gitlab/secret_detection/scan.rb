# frozen_string_literal: true

require 'toml-rb'
require 're2'
require 'logger'
require 'timeout'

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
      # ignore the scanning of a line which ends with the following keyword
      GITLEAKS_KEYWORD_IGNORE = 'gitleaks:allow'

      # Initializes the instance with logger along with following operations:
      # 1. Parse ruleset for the given +ruleset_path+(default: +RULESET_FILE_PATH+). Raises +RulesetParseError+
      # incase the operation fails.
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
      #
      # Returns an instance of SecretDetection::Response by following below structure:
      # {
      #     status: One of the SecretDetection::Status values
      #     results: [SecretDetection::Finding]
      # }
      def secrets_scan(blobs, timeout: DEFAULT_SCAN_TIMEOUT_SECS, blob_timeout: DEFAULT_BLOB_TIMEOUT_SECS)
        return SecretDetection::Response.new(SecretDetection::Status::INPUT_ERROR) unless validate_scan_input(blobs)

        Timeout.timeout(timeout) do
          matched_blobs = filter_by_keywords(blobs)

          next SecretDetection::Response.new(SecretDetection::Status::NOT_FOUND) if matched_blobs.empty?

          secrets = find_secrets_bulk(matched_blobs, blob_timeout)

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

      # returns only those blobs that contain atleast one of the keywords
      # from the keywords list
      def filter_by_keywords(blobs)
        matched_blobs = []

        blobs.each do |blob|
          matched_blobs << blob if keywords.any? { |keyword| blob.data.include?(keyword) }
        end

        matched_blobs.freeze
      end

      # finds secrets in the given list of blobs
      def find_secrets_bulk(blobs, blob_timeout)
        found_secrets = []

        blobs.each do |blob|
          found_secrets << Timeout.timeout(blob_timeout) { find_secrets(blob) }
        rescue Timeout::Error => e
          logger.error "Secret detection scan timed out on the blob(id:#{blob.id}): #{e}"

          found_secrets << SecretDetection::Finding.new(
            blob.id,
            SecretDetection::Status::BLOB_TIMEOUT
          )
        end

        found_secrets.flatten.freeze
      end

      # finds secrets in the given blob with a timeout circuit breaker
      def find_secrets(blob)
        secrets = []

        blob.data.each_line.with_index do |line, index|
          # ignore the line scan if it is suffixed with '#gitleaks:allow'
          next if line.end_with?(GITLEAKS_KEYWORD_IGNORE)

          patterns = pattern_matcher.match(line, :exception => false)
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
        logger.error "Secret detection scan failed on the blob(id:#{blob.id}): #{e}"

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

        timed_out_blobs = found_secrets.count { |el| el.status == SecretDetection::Status::BLOB_TIMEOUT }

        case timed_out_blobs
        when 0
          SecretDetection::Status::FOUND
        when found_secrets.length
          SecretDetection::Status::SCAN_TIMEOUT
        else
          SecretDetection::Status::FOUND_WITH_ERRORS
        end
      end
    end
  end
end
