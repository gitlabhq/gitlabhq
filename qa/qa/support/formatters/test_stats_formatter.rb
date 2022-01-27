# frozen_string_literal: true

module QA
  module Support
    module Formatters
      class TestStatsFormatter < RSpec::Core::Formatters::BaseFormatter
        RSpec::Core::Formatters.register(self, :stop)

        # Finish test execution
        #
        # @param [RSpec::Core::Notifications::ExamplesNotification] notification
        # @return [void]
        def stop(notification)
          return log(:warn, 'Missing QA_INFLUXDB_URL, skipping metrics export!') unless influxdb_url
          return log(:warn, 'Missing QA_INFLUXDB_TOKEN, skipping metrics export!') unless influxdb_token

          push_test_stats(notification.examples)
          push_fabrication_stats
        end

        private

        # Push test execution stats to influxdb
        #
        # @param [Array<RSpec::Core::Example>] examples
        # @return [void]
        def push_test_stats(examples)
          data = examples.map { |example| test_stats(example) }.compact

          influx_client.write(data: data)
          log(:debug, "Pushed #{data.length} test execution entries to influxdb")
        rescue StandardError => e
          log(:error, "Failed to push test execution stats to influxdb, error: #{e}")
        end

        # Push resource fabrication stats to influxdb
        #
        # @return [void]
        def push_fabrication_stats
          data = Tools::TestResourceDataProcessor.resources.flat_map do |resource, values|
            values.map { |v| fabrication_stats(resource: resource, **v) }
          end
          return if data.empty?

          influx_client.write(data: data)
          log(:debug, "Pushed #{data.length} resource fabrication entries to influxdb")
        rescue StandardError => e
          log(:error, "Failed to push fabrication stats to influxdb, error: #{e}")
        end

        # Transform example to influxdb compatible metrics data
        # https://github.com/influxdata/influxdb-client-ruby#data-format
        #
        # @param [RSpec::Core::Example] example
        # @return [Hash]
        def test_stats(example)
          file_path = example.metadata[:file_path].gsub('./qa/specs/features', '')
          api_fabrication = ((example.metadata[:api_fabrication] || 0) * 1000).round
          ui_fabrication = ((example.metadata[:browser_ui_fabrication] || 0) * 1000).round

          {
            name: 'test-stats',
            time: time,
            tags: {
              name: example.full_description,
              file_path: file_path,
              status: example.execution_result.status,
              reliable: example.metadata.key?(:reliable).to_s,
              quarantined: example.metadata.key?(:quarantine).to_s,
              retried: ((example.metadata[:retry_attempts] || 0) > 0).to_s,
              job_name: job_name,
              merge_request: merge_request,
              run_type: env('QA_RUN_TYPE') || run_type,
              stage: devops_stage(file_path),
              testcase: example.metadata[:testcase]
            },
            fields: {
              id: example.id,
              run_time: (example.execution_result.run_time * 1000).round,
              api_fabrication: api_fabrication,
              ui_fabrication: ui_fabrication,
              total_fabrication: api_fabrication + ui_fabrication,
              retry_attempts: example.metadata[:retry_attempts] || 0,
              job_url: QA::Runtime::Env.ci_job_url,
              pipeline_url: env('CI_PIPELINE_URL'),
              pipeline_id: env('CI_PIPELINE_ID')
            }
          }
        rescue StandardError => e
          log(:error, "Failed to transform example '#{example.id}', error: #{e}")
          nil
        end

        # Resource fabrication data point
        #
        # @param [String] resource
        # @param [String] info
        # @param [Symbol] fabrication_method
        # @param [Symbol] http_method
        # @param [Integer] fabrication_time
        # @return [Hash]
        def fabrication_stats(resource:, info:, fabrication_method:, http_method:, fabrication_time:, **)
          {
            name: 'fabrication-stats',
            time: time,
            tags: {
              resource: resource,
              fabrication_method: fabrication_method,
              http_method: http_method,
              run_type: env('QA_RUN_TYPE') || run_type,
              merge_request: merge_request
            },
            fields: {
              fabrication_time: fabrication_time,
              info: info,
              job_url: QA::Runtime::Env.ci_job_url
            }
          }
        end

        # Project name
        #
        # @return [String]
        def project_name
          @project_name ||= QA::Runtime::Env.ci_project_name
        end

        # Base ci job name
        #
        # @return [String]
        def job_name
          @job_name ||= QA::Runtime::Env.ci_job_name&.gsub(%r{ \d{1,2}/\d{1,2}}, '')
        end

        # Single common timestamp for all exported example metrics to keep data points consistently grouped
        #
        # @return [Time]
        def time
          @time ||= begin
            return Time.now unless env('CI_PIPELINE_CREATED_AT')

            DateTime.strptime(env('CI_PIPELINE_CREATED_AT')).to_time
          end
        end

        # Is a merge request execution
        #
        # @return [String]
        def merge_request
          @merge_request ||= (!!env('CI_MERGE_REQUEST_IID') || !!env('TOP_UPSTREAM_MERGE_REQUEST_IID')).to_s
        end

        # Test run type from staging (`gstg`, `gstg-cny`, `gstg-ref`), canary, preprod or production env
        #
        # @return [String, nil]
        def run_type
          return unless %w[staging staging-canary staging-ref canary preprod production].include?(project_name)

          @run_type ||= begin
            test_subset = if env('NO_ADMIN') == 'true'
                            'sanity-no-admin'
                          elsif env('SMOKE_ONLY') == 'true'
                            'sanity'
                          else
                            'full'
                          end

            "#{project_name}-#{test_subset}"
          end
        end

        # Print log message
        #
        # @param [Symbol] level
        # @param [String] message
        # @return [void]
        def log(level, message)
          QA::Runtime::Logger.public_send(level, "[influxdb exporter]: #{message}")
        end

        # Return non empty environment variable value
        #
        # @param [String] name
        # @return [String, nil]
        def env(name)
          return unless ENV[name] && !ENV[name].empty?

          ENV[name]
        end

        # Get spec devops stage
        #
        # @param [String] location
        # @return [String, nil]
        def devops_stage(file_path)
          file_path.match(%r{\d{1,2}_(\w+)/})&.captures&.first
        end

        # InfluxDb client
        #
        # @return [InfluxDB2::WriteApi]
        def influx_client
          @influx_client ||= InfluxDB2::Client.new(
            influxdb_url,
            influxdb_token,
            bucket: 'e2e-test-stats',
            org: 'gitlab-qa',
            precision: InfluxDB2::WritePrecision::NANOSECOND
          ).create_write_api
        end

        # InfluxDb instance url
        #
        # @return [String]
        def influxdb_url
          @influxdb_url ||= env('QA_INFLUXDB_URL')
        end

        # Influxdb token
        #
        # @return [String]
        def influxdb_token
          @influxdb_token ||= env('QA_INFLUXDB_TOKEN')
        end
      end
    end
  end
end
