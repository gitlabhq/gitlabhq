# frozen_string_literal: true

require "fog/google"

module QA
  module Support
    class KnapsackReport
      PROJECT = "gitlab-qa-resources"
      BUCKET = "knapsack-reports"
      BASE_PATH = "knapsack"
      FALLBACK_REPORT = "#{BASE_PATH}/master_report.json".freeze
      PATTERN_VAR_NAME = "KNAPSACK_TEST_FILE_PATTERN"
      DEFAULT_TEST_PATTERN = "qa/specs/features/**/*_spec.rb"
      EXAMPLE_RUNTIMES_PATH = "example_runtimes"
      RUNTIME_REPORT = "#{BASE_PATH}/#{EXAMPLE_RUNTIMES_PATH}/master_report.json".freeze

      class << self
        delegate :configure!, :upload_example_runtimes, to: :new
      end

      def initialize(logger = QA::Runtime::Logger.logger)
        @logger = logger
      end

      # Configure knapsack report
      #
      # * Setup variables
      # * Fetch latest report
      #
      # @return [void]
      def configure!
        return unless QA::Runtime::Env.knapsack?

        setup_logger!
        setup_environment!
      end

      # Create local knapsack report based on example runtime data and configure it to be used by knapsack
      #
      # Passing list of examples allows to craft a more precise report that will not have runtime data
      # for examples that will actually be skipped due to dynamic metadata which can cause uneven test distribution
      #
      # @param example_data [Hash<String, String>] example id list to be included in the report
      # @return [void]
      def create_local_report!(example_data)
        logger.info("Creating knapsack report from runtime data")
        runtime_report = JSON.load_file(RUNTIME_REPORT)
        report = example_data.each_with_object(Hash.new { |h, k| h[k] = 0 }) do |(id, status), report|
          next report[example_file_path(id)] += runtime_report[id] || 0.01 if status == "passed"

          # if example was not executed, add small runtime to the report
          # this is needed for knapsack to not consider all specs that got skipped dynamically as leftover specs
          # https://github.com/KnapsackPro/knapsack?tab=readme-ov-file#what-does-leftover-specs-mean
          report[example_file_path(id)] += 0.01
        end
        normalized_report = report
          .transform_values { |v| v.round(3) }
          .sort
          .to_h

        report_path = File.join(BASE_PATH, report_name)
        File.write(report_path, normalized_report.to_json)
        ENV["KNAPSACK_REPORT_PATH"] = report_path
      rescue StandardError => e
        ENV["KNAPSACK_REPORT_PATH"] = FALLBACK_REPORT
        logger.warn("Failed to create knapsack report: #{e}")
        logger.warn("Falling back to '#{FALLBACK_REPORT}'")
      end

      # Create and upload custom report based on data from JsonFormatter report files
      #
      # @param glob [String]
      # @return [void]
      def upload_example_runtimes(glob)
        raise "QA_RUN_TYPE must be set for custom report" unless run_type

        reports = Pathname.glob(glob).select { |file| file.extname == ".json" }
        raise "Glob '#{glob}' did not contain any valid report files!" if reports.empty?

        logger.info("Processing '#{reports.size}' report files")
        report = example_runtimes(reports).sort.to_h

        file = "#{EXAMPLE_RUNTIMES_PATH}/#{run_type}.json"
        logger.info("Uploading example runtime report '#{file}'")
        client.put_object(BUCKET, file, JSON.pretty_generate(report))
      end

      # Merged example runtime data report from all report files
      #
      # @return [Hash<String, Number>]
      def create_merged_runtime_report
        logger.info("Fetching all example runtime data from GCS '#{BUCKET}' bucket")
        items = client.list_objects(BUCKET, prefix: EXAMPLE_RUNTIMES_PATH).items
        logger.info("Fetched example runtime files #{items.map(&:name)}, creating merged knapsack report")
        client.list_objects(BUCKET, prefix: EXAMPLE_RUNTIMES_PATH).items
          .each_with_object({}) do |report, runtimes|
            json = JSON.parse(client.get_object(BUCKET, report.name)[:body])

            # merge report and keep only the longest runtime
            json.each { |id, runtime| runtimes[id] = runtime unless (runtimes[id] || 0) > runtime }
          end
      end

      # Create knapsack report from example runtime data
      #
      # @param runtime_report [Hash<String, Number>]
      # @return [Hash<String, Number>]
      def create_knapsack_report(runtime_report)
        runtime_report.each_with_object(Hash.new { |hsh, key| hsh[key] = 0 }) do |(id, runtime), spec_runtimes|
          spec_runtimes[example_file_path(id)] += runtime
        end
      end

      private

      attr_reader :logger

      delegate :run_type, to: QA::Runtime::Env

      # Setup knapsack logger
      #
      # @return [void]
      def setup_logger!
        Knapsack.logger = logger
      end

      # Set knapsack environment variables
      #
      # @return [void]
      def setup_environment!
        ENV["KNAPSACK_TEST_DIR"] = "qa/specs/features"
        ENV["KNAPSACK_REPORT_PATH"] = FALLBACK_REPORT
        return unless ENV[PATTERN_VAR_NAME].blank?

        ENV[PATTERN_VAR_NAME] = DEFAULT_TEST_PATTERN
      end

      # GCS client
      #
      # @return [Fog::Storage::GoogleJSON]
      def client
        @client ||= Fog::Storage::Google.new(google_project: PROJECT, **gcs_credentials)
      end

      # Base path of knapsack report
      #
      # @return [String]
      def report_base_path
        @report_base_path ||= "knapsack"
      end

      # GCS credentials json
      #
      # @return [Hash]
      def gcs_credentials
        json_key = ENV["QA_KNAPSACK_REPORT_GCS_CREDENTIALS"] || raise(
          "QA_KNAPSACK_REPORT_GCS_CREDENTIALS env variable is required!"
        )
        return { google_json_key_location: json_key } if File.exist?(json_key)

        { google_json_key_string: json_key }
      end

      # Get example runtimes from JsonFormatter report files
      #
      # @param reports [Array<Pathname>]
      # @return [Hash<Number>]
      def example_runtimes(reports)
        reports
          .flat_map { |report| JSON.load_file(report, symbolize_names: true) }
          .each_with_object({}) do |json, runtimes|
            json[:examples].each do |ex|
              next if ex[:ignore_runtime_data] || ex[:status] != "passed"

              # keep the longest running example
              runtimes[ex[:id]] = ex[:run_time] unless (runtimes[:id] || 0) > ex[:run_time]
            end
          end
      end

      # Knapsack report file name
      #
      # @return [String]
      def report_name
        "#{ENV['CI_JOB_NAME_SLUG'] || 'local'}-knapsack-report.json"
      end

      # Extract file path from example id
      #
      # @param example_id [String]
      # @return [String]
      def example_file_path(example_id)
        example_id.match(/(\S+)\[\S+\]/)[1].gsub("./", "")
      end
    end
  end
end
