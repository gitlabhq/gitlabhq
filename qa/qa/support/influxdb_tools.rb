# frozen_string_literal: true

module QA
  module Support
    # Common tools for use with influxdb metrics setup
    #
    module InfluxdbTools
      # @return [String] bucket for storing all test run metrics
      INFLUX_TEST_METRICS_BUCKET = "e2e-test-stats"
      # @return [String] bucket for storing metrics from main runs
      INFLUX_MAIN_TEST_METRICS_BUCKET = "e2e-test-stats-main"
      # @return [Array] live environment names
      LIVE_ENVS = %w[staging staging-canary staging-ref canary preprod production].freeze

      private

      delegate :ci_project_name, to: "QA::Runtime::Env"

      # Query client
      #
      # @return [QueryApi]
      def query_api
        @query_api ||= influx_client.create_query_api
      end

      # Write client
      #
      # @return [WriteApi]
      def write_api
        @write_api ||= influx_client.create_write_api
      end

      # InfluxDb client
      #
      # @return [InfluxDB2::Client]
      def influx_client
        @influx_client ||= InfluxDB2::Client.new(
          ENV["QA_INFLUXDB_URL"] || raise("Missing QA_INFLUXDB_URL env variable"),
          ENV["QA_INFLUXDB_TOKEN"] || raise("Missing QA_INFLUXDB_TOKEN env variable"),
          bucket: INFLUX_TEST_METRICS_BUCKET,
          org: "gitlab-qa",
          precision: InfluxDB2::WritePrecision::NANOSECOND,
          read_timeout: ENV["QA_INFLUXDB_TIMEOUT"]&.to_i || 60,
          open_timeout: ENV["QA_INFLUXDB_TIMEOUT"]&.to_i || 60
        )
      end

      # Test run type
      # Automatically infer for staging (`gstg`, `gstg-cny`, `gstg-ref`), canary, preprod or production env
      #
      # @return [String, nil]
      def run_type
        @run_type ||= if env('QA_RUN_TYPE')
                        env('QA_RUN_TYPE')
                      elsif LIVE_ENVS.exclude?(ci_project_name)
                        nil
                      else
                        test_subset = if env('SMOKE_ONLY') == 'true'
                                        'sanity'
                                      else
                                        'full'
                                      end

                        "#{ci_project_name}-#{test_subset}"
                      end
      end

      # Merge request iid
      #
      # @return [String]
      def merge_request_iid
        env('CI_MERGE_REQUEST_IID') || env('TOP_UPSTREAM_MERGE_REQUEST_IID')
      end

      # Return non empty environment variable value
      #
      # @param [String] name
      # @return [String, nil]
      def env(name)
        return unless ENV[name] && !ENV[name].empty?

        ENV[name]
      end
    end
  end
end
