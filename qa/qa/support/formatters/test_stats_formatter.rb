# frozen_string_literal: true

module QA
  module Support
    module Formatters
      class TestStatsFormatter < RSpec::Core::Formatters::BaseFormatter
        include Support::InfluxdbTools

        RSpec::Core::Formatters.register(self, :stop)

        # Finish test execution
        #
        # @param [RSpec::Core::Notifications::ExamplesNotification] notification
        # @return [void]
        def stop(notification)
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

          write_api.write(data: data)
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

          write_api.write(data: data)
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
              status: status(example),
              smoke: example.metadata.key?(:smoke).to_s,
              reliable: example.metadata.key?(:reliable).to_s,
              quarantined: quarantined(example.metadata),
              retried: (retry_attempts(example.metadata) > 0).to_s,
              job_name: job_name,
              merge_request: merge_request,
              run_type: run_type,
              stage: devops_stage(file_path),
              product_group: example.metadata[:product_group],
              testcase: example.metadata[:testcase]
            },
            fields: {
              id: example.id,
              run_time: (example.execution_result.run_time * 1000).round,
              api_fabrication: api_fabrication,
              ui_fabrication: ui_fabrication,
              total_fabrication: api_fabrication + ui_fabrication,
              retry_attempts: retry_attempts(example.metadata),
              job_url: QA::Runtime::Env.ci_job_url,
              pipeline_url: env('CI_PIPELINE_URL'),
              pipeline_id: env('CI_PIPELINE_ID'),
              job_id: env('CI_JOB_ID'),
              merge_request_iid: merge_request_iid
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
        def fabrication_stats(resource:, info:, fabrication_method:, http_method:, fabrication_time:, timestamp:, **)
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
              job_url: QA::Runtime::Env.ci_job_url,
              timestamp: timestamp
            }
          }
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
          (!!merge_request_iid).to_s
        end

        # Is spec quarantined
        #
        # @param [Hash] metadata
        # @return [String]
        def quarantined(metadata)
          return "false" unless metadata.key?(:quarantine)
          return "true" unless metadata[:quarantine].is_a?(Hash)

          (!Specs::Helpers::Quarantine.quarantined_different_context?(metadata[:quarantine])).to_s
        end

        # Return a more detailed status
        #
        # - if test is failed or pending, return rspec status
        # - if test passed but had more than 1 attempt, consider test flaky
        #
        # @param [RSpec::Core::Example] example
        # @return [String]
        def status(example)
          rspec_status = example.execution_result.status
          return rspec_status if [:pending, :failed].include?(rspec_status)

          retry_attempts(example.metadata) > 0 ? :flaky : :passed
        end

        # Retry attempts
        #
        # @param [Hash] metadata
        # @return [Integer]
        def retry_attempts(metadata)
          metadata[:retry_attempts] || 0
        end

        # Print log message
        #
        # @param [Symbol] level
        # @param [String] message
        # @return [void]
        def log(level, message)
          QA::Runtime::Logger.public_send(level, "[influxdb exporter]: #{message}")
        end

        # Get spec devops stage
        #
        # @param [String] location
        # @return [String, nil]
        def devops_stage(file_path)
          file_path.match(%r{\d{1,2}_(\w+)/})&.captures&.first
        end
      end
    end
  end
end
