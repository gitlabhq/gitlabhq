# frozen_string_literal: true

require 'csv'

module QA
  module Tools
    class MigrateInfluxDataToGcsCsv < MigrateInfluxDataToGcs
      TEST_STATS_FIELDS = %w[id testcase file_path name product_group stage job_id job_name
        job_url pipeline_id pipeline_url merge_request merge_request_iid smoke quarantined
        retried retry_attempts run_time run_type status ui_fabrication api_fabrication total_fabrication].freeze
      FABRICATION_STATS_FIELDS = %w[timestamp resource fabrication_method http_method run_type
        merge_request fabrication_time info job_url].freeze

      def initialize(args)
        super

        @hours = args[:hours].to_i
      end

      # Fetch data from Influx DB, store as CSV and upload to GCS
      #
      # @return [void]
      def migrate_data
        INFLUX_BUCKETS.each do |bucket|
          INFLUX_STATS_TYPE.each do |stats_type|
            if bucket == Support::InfluxdbTools::INFLUX_MAIN_TEST_METRICS_BUCKET && stats_type == "fabrication-stats"
              break
            end

            file_name = "#{bucket.end_with?('main') ? 'main' : 'all'}-#{stats_type}_#{Time.now.to_i}.csv"
            rows = influx_to_csv(bucket, stats_type, file_name)

            if rows.empty?
              QA::Runtime::Logger.warn("No data to upload for bucket: '#{bucket}' and stats: '#{stats_type}'")
              next
            end

            # Upload to Google Cloud Storage
            upload_to_gcs(QA_METRICS_GCS_BUCKET_NAME, file_name)
          end
        end
      end

      private

      # Query InfluxDB and store in JSON
      #
      # @param [String] influx_bucket bucket to fetch data
      # @param [String] stats_type of data to fetch
      # @param [String] data_file_name to store data
      # @return void
      def influx_to_csv(influx_bucket, stats_type, data_file_name)
        QA::Runtime::Logger.info("Fetching Influx data for the last #{@hours} hours")
        all_runs = query_api.query(query: query(influx_bucket, stats_type, "start: -#{@hours}h"))
        CSV.open(data_file_name, "wb", col_sep: '|') do |csv|
          stats_array = stats_type == "test-stats" ? TEST_STATS_FIELDS : FABRICATION_STATS_FIELDS
          all_runs.each do |table|
            table.records.each do |record|
              csv << stats_array.map { |key| record.values[key] }
            end
          end
          QA::Runtime::Logger.info("File #{data_file_name} contains #{all_runs.count} rows")
        end

        all_runs
      end

      # Upload file to GCS
      #
      # @param [String] bucket to be uploaded to
      # @param [String] backup_file_path of file to be uploaded
      # @return [void]
      def upload_to_gcs(bucket, backup_file_path)
        file_path = backup_file_path.tr('_0-9', '')

        # Backup older file
        begin
          QA::Runtime::Logger.info("Backing up older file to #{backup_file_path}")
          gcs_client.copy_object(bucket, file_path, bucket, backup_file_path)
        rescue Google::Apis::ClientError
          QA::Runtime::Logger.warn("File #{file_path} is not found in GCS bucket, continuing with upload...")
        end

        # Upload new file
        begin
          file = gcs_client.put_object(bucket, file_path, File.new(backup_file_path, "r"), force: true)
          QA::Runtime::Logger.info("File #{file_path} uploaded to gs://#{bucket}/#{file.name}")
        rescue StandardError => e
          QA::Runtime::Logger.error("Failed uploading '#{file_path}' to GCS. Error: #{e.message}.")
          raise e
        end
      end
    end
  end
end
