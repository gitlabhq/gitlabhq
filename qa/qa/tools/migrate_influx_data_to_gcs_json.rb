# frozen_string_literal: true

require 'date'
require 'active_support/core_ext/date'

module QA
  module Tools
    class MigrateInfluxDataToGcsJson < MigrateInfluxDataToGcs
      def initialize(args)
        super

        @year = args[:year]&.to_i
        @month = args[:month]&.to_i
        @day = args[:day]&.to_i

        raise("An year must be provided") unless @year
        raise("An month must be provided") unless @month
      end

      # Fetch data from Influx DB, store as JSON and upload to GCS
      #
      # @return [void]
      def migrate_data
        create_tmp_dir

        INFLUX_BUCKETS.each do |bucket|
          INFLUX_STATS_TYPE.each do |stats_type|
            if bucket == Support::InfluxdbTools::INFLUX_MAIN_TEST_METRICS_BUCKET && stats_type == "fabrication-stats"
              break
            end

            last_day_of_month = DateTime.new(@year, @month, 1).end_of_month.day

            days = @day ? [@day] : (1..last_day_of_month).to_a

            days.each do |day|
              date = DateTime.new(@year, @month, day)
              start_date = date.beginning_of_day.rfc3339
              end_date = date.end_of_day.rfc3339

              file_name = "#{bucket.end_with?('main') ? 'main' : 'all'}_#{stats_type}_#{date.to_date.iso8601}.json"
              file_path = File.join('tmp', file_name)
              influx_to_json(bucket, stats_type, file_path, "start: #{start_date}, stop: #{end_date}")

              # Upload to Google Cloud Storage
              upload_to_gcs(QA_METRICS_GCS_BUCKET_NAME, file_path, file_name)
            end
          end
        end
      end

      private

      # Query InfluxDB and store in JSON
      #
      # @param [String] influx_bucket bucket to fetch data
      # @param [String] stats_type of data to fetch
      # @param [String] data_file_name to store data
      # @param [String] range for influxdb query
      # @return [void]
      def influx_to_json(influx_bucket, stats_type, data_file_name, range)
        QA::Runtime::Logger.info("Fetching Influx data for stats: '#{stats_type}', " \
          "bucket: '#{influx_bucket}' in range #{range}...")
        all_runs = []

        retry_on_exception(sleep_interval: 30) do
          all_runs = query_api.query(query: query(influx_bucket, stats_type, range))
        end

        record_objects = []
        all_runs.each do |table|
          table.records.each do |record|
            record_objects << (

              if stats_type == 'test-stats'
                test_stats(stats_type, record)
              else
                fabrication_stats(stats_type, record)
              end

            )
          end
        end

        begin
          File.open(data_file_name, 'w') { |f| f.write(record_objects.to_json) }
          QA::Runtime::Logger.info("Wrote file #{data_file_name} containing #{all_runs.count} rows to disk")
        rescue StandardError => e
          QA::Runtime::Logger.error("Failed to write data to file: '#{data_file_name}', " \
            "influx_bucket: #{influx_bucket}, stats_type: #{stats_type}, error: #{e}")
        end
      end

      # Produces a test_stats Hash
      #
      # @param [String] stats_type of data
      # @param [String] record to get the data from
      # @return [Hash]
      def test_stats(stats_type, record)
        {
          name: stats_type,
          time: record.values['_time'],
          tags: tags(record.values),
          fields: fields(record.values)
        }
      end

      # Produces a fabrication_stats Hash
      #
      # @param [String] stats_type of data
      # @param [String] record to get the data from
      # @return [Hash]
      def fabrication_stats(stats_type, record)
        {
          name: stats_type,
          time: record.values['_time'],
          tags: {
            resource: record.values['resource'],
            fabrication_method: record.values['fabrication_method'],
            http_method: record.values['http_method'],
            run_type: record.values['run_type'],
            merge_request: record.values['merge_request']
          },
          fields: {
            fabrication_time: record.values['fabrication_time'],
            info: record.values['info']&.force_encoding('UTF-8'),
            job_url: record.values['job_url'],
            timestamp: record.values['timestamp']
          }
        }
      end

      # Produces a tags Hash
      #
      # @param [String] values record's values to get the data from
      # @return [Hash]
      def tags(values)
        tags = values.slice('name', 'file_path', 'status', 'smoke',
          'quarantined', 'job_name', 'merge_request', 'run_type', 'stage',
          'product_group', 'testcase', 'exception_class')

        # custom_test_metrics
        tags['import_repo'] = values['import_repo']
        tags['import_type'] = values['import_type']

        tags
      end

      # Produces a fields Hash
      #
      # @param [String] values record's values to get the data from
      # @return [Hash]
      def fields(values)
        fields = values.slice('id', 'run_time', 'api_fabrication', 'ui_fabrication',
          'total_fabrication', 'job_url', 'pipeline_url', 'pipeline_id',
          'job_id', 'merge_request_iid', 'failure_issue')

        fields['failure_exception'] = values['failure_exception']&.force_encoding('UTF-8')
        fields['import_time'] = values['import_time'] # custom_test_metrics

        fields
      end

      # Create a 'tmp' directory
      #
      # @return [String]
      def create_tmp_dir
        FileUtils.mkdir_p('tmp/')
      end

      # Upload file to GCS
      #
      # @param [String] bucket to be uploaded to
      # @param [String] file_path of file to be uploaded
      # @param [String] file_name of file to be uploaded
      # @return [void]
      def upload_to_gcs(bucket, file_path, file_name)
        retry_on_exception(sleep_interval: 30) do
          file = gcs_client.put_object(bucket, file_name, File.new(file_path, "r"), force: true)
          QA::Runtime::Logger.info("Uploaded file #{file_path} to #{gcs_url(bucket, file)}")
        end
      end

      # Construct the url of the uploaded file in GCS
      # @param [String] bucket name the file is uploaded to
      # @param [String] file uploaded to gcs
      #
      # @return [String]
      def gcs_url(bucket, file)
        "https://storage.cloud.google.com/#{bucket}/#{file.name}"
      end
    end
  end
end
