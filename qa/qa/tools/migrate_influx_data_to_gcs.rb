# frozen_string_literal: true

module QA
  module Tools
    class MigrateInfluxDataToGcs
      include Support::GcsTools
      include Support::InfluxdbTools
      include Support::Repeater
      include Support::Retrier

      RETRY_BACK_OFF_DELAY = 30
      MAX_RETRY_ATTEMPTS = 3

      QA_METRICS_GCS_BUCKET_NAME = ENV['QA_METRICS_GCS_BUCKET_NAME'] ||
        raise('Missing QA_METRICS_GCS_BUCKET_NAME env variable')

      INFLUX_STATS_TYPE = %w[test-stats fabrication-stats].freeze
      INFLUX_BUCKETS = [INFLUX_TEST_METRICS_BUCKET, INFLUX_MAIN_TEST_METRICS_BUCKET].freeze

      def initialize(_args)
        @retry_backoff = 0
      end

      # Run Influx Migrator
      #
      # @param [Hash] the arguments hash
      # @return [void]
      def self.run(args)
        migrator = new(args)

        migrator.migrate_data
      end

      private

      # FluxQL query used to fetch data
      #
      # @param [String] influx_bucket bucket to fetch data
      # @param [String] stats_type of data to fetch
      # @param [String] range for influxdb query
      # @return [void]
      def query(influx_bucket, stats_type, range)
        <<~QUERY
          from(bucket: "#{influx_bucket}")
          |> range(#{range})
          |> filter(fn: (r) => r["_measurement"] == "#{stats_type}")
          |> pivot(rowKey:["_time"], columnKey: ["_field"], valueColumn: "_value")
        QUERY
      end
    end
  end
end
