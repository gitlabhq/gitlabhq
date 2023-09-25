# frozen_string_literal: true

require 'csv'
require "fog/google"

module QA
  module Tools
    class MigrateInfluxDataToGcs
      include Support::InfluxdbTools

      # Google Cloud Storage bucket from which Snowpipe would pull data into Snowflake
      QA_GCS_BUCKET_NAME = ENV["QA_GCS_BUCKET_NAME"] || raise("Missing QA_GCS_BUCKET_NAME env variable")
      QA_GCS_PROJECT_ID = ENV["QA_GCS_PROJECT_ID"] || raise("Missing QA_GCS_PROJECT_ID env variable")
      QA_GCS_JSON_KEY_FILE = ENV["QA_GCS_JSON_KEY_FILE"] || raise("Missing QA_GCS_JSON_KEY_FILE env variable")
      INFLUX_STATS_TYPE = %w[test-stats fabrication-stats].freeze
      INFLUX_BUCKETS = [Support::InfluxdbTools::INFLUX_TEST_METRICS_BUCKET,
        Support::InfluxdbTools::INFLUX_MAIN_TEST_METRICS_BUCKET].freeze
      TEST_STATS_FIELDS = %w[id testcase file_path name product_group stage job_id job_name
        job_url pipeline_id pipeline_url merge_request merge_request_iid smoke reliable quarantined
        retried retry_attempts run_time run_type status ui_fabrication api_fabrication total_fabrication].freeze
      FABRICATION_STATS_FIELDS = %w[timestamp resource fabrication_method http_method run_type
        merge_request fabrication_time info job_url].freeze

      def initialize(range)
        @range = range.to_i
      end

      # Run Influx Migrator
      # @param [Integer] the last x hours for which data is required
      # @return [void]
      def self.run(range: 6)
        migrator = new(range)

        QA::Runtime::Logger.info("Fetching Influx data for the last #{range} hours")
        migrator.migrate_data
      end

      # Fetch data from Influx DB , store as CSV and upload to GCS
      # @return [void]
      def migrate_data
        INFLUX_BUCKETS.each do |bucket|
          INFLUX_STATS_TYPE.each do |stats_type|
            if bucket == Support::InfluxdbTools::INFLUX_MAIN_TEST_METRICS_BUCKET && stats_type == "fabrication-stats"
              break
            end

            file_name = "#{bucket.end_with?('main') ? 'main' : 'all'}-#{stats_type}_#{Time.now.to_i}.csv"
            influx_to_csv(bucket, stats_type, file_name)

            # Upload to Google Cloud Storage
            upload_to_gcs(QA_GCS_BUCKET_NAME, file_name)
          end
        end
      end

      private

      # FluxQL query used to fetch data
      # @param [String] influx bucket to fetch data
      # @param [String] Type of data to fetch
      # @return [String] query string
      def query(influx_bucket, stats_type)
        <<~QUERY
        from(bucket: "#{influx_bucket}")
        |> range(start: -#{@range}h)
        |> filter(fn: (r) => r["_measurement"] == "#{stats_type}")
        |> pivot(rowKey:["_time"], columnKey: ["_field"], valueColumn: "_value")
        |> drop(columns: ["_start", "_stop", "result", "table", "_time", "_measurement"])
        QUERY
      end

      # Query InfluxDB and store in CSV
      # @param [String] influx bucket to fetch data
      # @param [String] Type of data to fetch
      # @param [String] CSV filename to store data
      # @return void
      def influx_to_csv(influx_bucket, stats_type, data_file_name)
        all_runs = query_api.query(query: query(influx_bucket, stats_type))
        CSV.open(data_file_name, "wb", col_sep: '|') do |csv|
          stats_array = stats_type == "test-stats" ? TEST_STATS_FIELDS : FABRICATION_STATS_FIELDS
          all_runs.each do |table|
            table.records.each do |record|
              csv << stats_array.map { |key| record.values[key] }
            end
          end
          QA::Runtime::Logger.info("File #{data_file_name} contains #{all_runs.count} rows")
        end
      end

      # Fetch GCS Credentials
      # @return [Hash] GCS Credentials
      def gcs_credentials
        json_key = ENV["QA_GCS_JSON_KEY_FILE"] || raise(
          "QA_GCS_JSON_KEY_FILE env variable is required!"
        )
        return { google_json_key_location: json_key } if File.exist?(json_key)

        { google_json_key_string: json_key }
      end

      # Upload file to GCS
      # @param [String] bucket to be uploaded to
      # @param [String] path of file to be uploaded
      # return void
      def upload_to_gcs(bucket, backup_file_path)
        client = Fog::Storage::Google.new(google_project: QA_GCS_PROJECT_ID, **gcs_credentials)
        file_path = backup_file_path.tr('_0-9', '')

        # Backup older file
        begin
          QA::Runtime::Logger.info("Backing up older file to #{backup_file_path}")
          client.copy_object(bucket, file_path, bucket, backup_file_path)
        rescue Google::Apis::ClientError
          QA::Runtime::Logger.warn("File #{file_path} is not found in GCS bucket, continuing with upload...")
        end

        # Upload new file
        file = client.put_object(bucket, file_path, File.new(backup_file_path, "r"), force: true)
        QA::Runtime::Logger.info("File #{file_path} uploaded to gs://#{bucket}/#{file.name}")
      end
    end
  end
end
