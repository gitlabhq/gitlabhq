# frozen_string_literal: true

require "fog/google"

module QA
  module Tools
    class KnapsackReport
      extend SingleForwardable

      PROJECT = "gitlab-qa-resources"
      BUCKET = "knapsack-reports"

      def_delegators :new, :configure!, :move_regenerated_report, :download_report, :upload_report

      # Configure knapsack report
      #
      # * Setup variables
      # * Fetch latest report
      #
      # @return [void]
      def configure!
        ENV["KNAPSACK_TEST_FILE_PATTERN"] ||= "qa/specs/features/**/*_spec.rb"
        ENV["KNAPSACK_REPORT_PATH"] = report_path

        Knapsack.logger = QA::Runtime::Logger.logger

        download_report
      end

      # Download knapsack report from gcs bucket
      #
      # @return [void]
      def download_report
        logger.debug("Downloading latest knapsack report for '#{report_name}' to '#{report_path}'")
        file = client.get_object(BUCKET, report_file)
        File.write(report_path, file[:body])
      rescue StandardError => e
        ENV["KNAPSACK_REPORT_PATH"] = "knapsack/master_report.json"
        logger.warn("Failed to fetch latest knapsack report: #{e}")
        logger.warn("Falling back to 'knapsack/master_report.json'")
      end

      # Rename and move new regenerated report to a separate folder used to indicate report name
      #
      # @return [void]
      def move_regenerated_report
        return unless ENV["KNAPSACK_GENERATE_REPORT"] == "true"

        path = "tmp/knapsack/#{report_name}"
        FileUtils.mkdir_p(path)

        # Use path from knapsack config in case of fallback to master_report.json
        FileUtils.cp(Knapsack.report.report_path, "#{path}/#{ENV['CI_NODE_INDEX']}.json")
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
          next logger.warn("Knapsack generated empty report for '#{name}', skipping upload!") if report.empty?

          logger.info("Uploading latest knapsack report '#{file}'")
          client.put_object(BUCKET, file, JSON.pretty_generate(report))
        rescue StandardError => e
          logger.error("Failed to upload knapsack report for '#{name}'. Error: #{e}")
        end
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
          google_json_key_location: gcs_credentials
        )
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
        @report_name ||= ENV["CI_JOB_NAME"].split(" ").first.tr(":", "-")
      end

      # Path to GCS credentials json
      #
      # @return [String]
      def gcs_credentials
        @gcs_credentials ||= ENV["QA_KNAPSACK_REPORT_GCS_CREDENTIALS"] || raise(
          "QA_KNAPSACK_REPORT_GCS_CREDENTIALS env variable is required!"
        )
      end
    end
  end
end
