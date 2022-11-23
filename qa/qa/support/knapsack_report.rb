# frozen_string_literal: true

require "fog/google"

module QA
  module Support
    class KnapsackReport
      PROJECT = "gitlab-qa-resources"
      BUCKET = "knapsack-reports"
      FALLBACK_REPORT = "knapsack/master_report.json"

      class << self
        delegate :configure!, :move_regenerated_report, :download_report, :upload_report, to: :new
      end

      def initialize(report_name = nil)
        @report_name = report_name
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
        download_report
      end

      # Download knapsack report from gcs bucket
      #
      # @return [void]
      def download_report
        logger.info("Downloading latest knapsack report for '#{report_name}' to '#{report_path}'")
        return logger.info("Report already exists, skipping!") if File.exist?(report_path)

        file = client.get_object(BUCKET, report_file)
        File.write(report_path, file[:body])
      rescue StandardError => e
        ENV["KNAPSACK_REPORT_PATH"] = FALLBACK_REPORT
        logger.warn("Failed to fetch latest knapsack report: #{e}")
        logger.warn("Falling back to '#{FALLBACK_REPORT}'")
      end

      # Rename and move new regenerated report to a separate folder used to indicate report name
      #
      # @return [void]
      def move_regenerated_report
        return unless ENV["KNAPSACK_GENERATE_REPORT"] == "true"

        tmp_path = "tmp/knapsack/#{report_name}"
        FileUtils.mkdir_p(tmp_path)

        # Use path from knapsack config in case of fallback to master_report.json
        knapsack_report_path = Knapsack.report.report_path
        logger.debug("Moving regenerated #{knapsack_report_path} to save as artifact")
        FileUtils.cp(knapsack_report_path, "#{tmp_path}/#{ENV['CI_NODE_INDEX']}.json")
      end

      # Merge and upload knapsack report to gcs bucket
      #
      # Fetches all files defined in glob and uses parent folder as report name
      #
      # @param [String] glob
      # @return [void]
      def upload_report(glob)
        reports = Pathname.glob(glob).each_with_object(Hash.new { |hsh, key| hsh[key] = [] }) do |report, hash|
          next unless report.extname == ".json"

          hash[report.parent.basename.to_s].push(report)
        end
        return logger.error("Glob '#{glob}' did not contain any valid report files!") if reports.empty?

        reports.each do |name, jsons|
          file = "#{name}.json"

          report = jsons
            .map { |json| JSON.parse(File.read(json)) }
            .reduce({}, :merge)
            .sort_by { |k, v| v } # sort report by execution time
            .to_h
          next logger.warn("Knapsack generated empty report for '#{name}', skipping upload!") if report.empty?

          logger.info("Uploading latest knapsack report '#{file}'")
          client.put_object(BUCKET, file, JSON.pretty_generate(report))
        rescue StandardError => e
          logger.error("Failed to upload knapsack report for '#{name}'. Error: #{e}")
        end
      end

      private

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
        ENV["KNAPSACK_TEST_FILE_PATTERN"] ||= "qa/specs/features/**/*_spec.rb"
        ENV["KNAPSACK_TEST_DIR"] = "qa/specs"
        ENV["KNAPSACK_REPORT_PATH"] = report_path
      end

      # Logger instance
      #
      # @return [ActiveSupport::Logger]
      def logger
        QA::Runtime::Logger.logger
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

      # Knapsack report path
      #
      # @return [String]
      def report_path
        @report_path ||= "#{report_base_path}/#{report_file}"
      end

      # Knapsack report name
      #
      # @return [String]
      def report_file
        @report_file ||= "#{report_name}.json"
      end

      # Report name
      #
      # Infer report name from ci job name
      # Remove characters incompatible with gcs bucket naming from job names like ee:instance-parallel
      #
      # @return [String]
      def report_name
        @report_name ||= ENV["QA_KNAPSACK_REPORT_NAME"] || ENV["CI_JOB_NAME"].split(" ").first.tr(":", "-")
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
    end
  end
end
