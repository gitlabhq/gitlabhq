# frozen_string_literal: true

require "fog/google"

module QA
  module Tools
    class KnapsackReport
      PROJECT = "gitlab-qa-resources"
      BUCKET = "knapsack-reports"

      class << self
        def download
          new.download_report
        end

        def upload(glob)
          new.upload_report(glob)
        end
      end

      def initialize
        ENV["KNAPSACK_REPORT_PATH"] || raise("KNAPSACK_REPORT_PATH env var is required!")
        ENV["QA_KNAPSACK_REPORT_GCS_CREDENTIALS"] || raise("QA_KNAPSACK_REPORT_GCS_CREDENTIALS env var is required!")
      end

      # Download knapsack report from gcs bucket
      #
      # @return [void]
      def download_report
        logger.info("Downloading latest knapsack report '#{report_file}'")
        file = client.get_object(BUCKET, report_file)

        logger.info("Saving latest knapsack report to '#{report_path}'")
        File.write(report_path, file[:body])
      end

      # Merge and upload knapsack report to gcs bucket
      #
      # @param [String] glob
      # @return [void]
      def upload_report(glob)
        reports = Dir[glob]
        return logger.error("Pattern '#{glob}' did not match any files!") if reports.empty?

        report = reports
          .map { |path| JSON.parse(File.read(path)) }
          .reduce({}, :merge)
        return logger.error("Knapsack generated empty report, skipping upload!") if report.empty?

        logger.info("Uploading latest knapsack report '#{report_file}'")
        client.put_object(BUCKET, report_file, JSON.pretty_generate(report))
      end

      private

      # Logger instance
      #
      # @return [Logger]
      def logger
        @logger ||= Logger.new($stdout)
      end

      # GCS client
      #
      # @return [Fog::Storage::GoogleJSON]
      def client
        @client ||= Fog::Storage::Google.new(
          google_project: PROJECT,
          google_json_key_location: ENV["QA_KNAPSACK_REPORT_GCS_CREDENTIALS"]
        )
      end

      # Knapsack report path
      #
      # @return [String]
      def report_path
        @report_path ||= ENV["KNAPSACK_REPORT_PATH"]
      end

      # Knapsack report name
      #
      # @return [String]
      def report_file
        @report_name ||= report_path.split("/").last
      end
    end
  end
end
