# frozen_string_literal: true

require "active_support/core_ext/string/conversions"

module QA
  module Tools
    module Ci
      class TestMetrics
        include Helpers
        include Support::InfluxdbTools

        def initialize(metrics_file_glob)
          @metrics_file_glob = metrics_file_glob
        end

        def self.export(metrics_file_glob)
          new(metrics_file_glob).export
        end

        # Export metrics to main bucket
        #
        # @return [void]
        def export
          return logger.warn("No files matched pattern '#{metrics_file_glob}'") if metrics_files.empty?

          logger.info("Exporting #{metrics_data.size} entries to influxdb")
          influx_client
            .create_write_api(write_options: write_options)
            .write(data: metrics_data, bucket: INFLUX_MAIN_TEST_METRICS_BUCKET)
        end

        private

        attr_reader :metrics_file_glob

        # Write options for influxdb
        #
        # @return [InfluxDB::WriteOptions]
        def write_options
          InfluxDB2::WriteOptions.new(
            write_type: InfluxDB2::WriteType::BATCHING,
            batch_size: 100,
            max_retries: 3
          )
        end

        # Metrics data files
        #
        # @return [Array]
        def metrics_files
          @metrics_files ||= Dir.glob(metrics_file_glob)
        end

        # Test metrics data
        #
        # @return [Array<Hash>]
        def metrics_data
          @metrics_data ||= metrics_files
            .flat_map { |file| JSON.parse(File.read(file), symbolize_names: true) }
            .map { |entry| entry.merge(time: entry[:time].to_time) }
        end
      end
    end
  end
end
