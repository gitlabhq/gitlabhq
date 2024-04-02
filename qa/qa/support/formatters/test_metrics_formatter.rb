# frozen_string_literal: true

require "active_support/core_ext/string/conversions"

module QA
  module Support
    module Formatters
      class TestMetricsFormatter < RSpec::Core::Formatters::BaseFormatter
        include Support::InfluxdbTools

        CUSTOM_METRICS_KEY = :custom_test_metrics

        RSpec::Core::Formatters.register(self, :stop)

        # Finish test execution
        #
        # @param [RSpec::Core::Notifications::ExamplesNotification] notification
        # @return [void]
        def stop(notification)
          return log(:warn, "Missing run_type, skipping metrics export!") unless run_type

          parse_execution_data(notification.examples)

          push_test_metrics
          push_fabrication_metrics
          save_test_metrics
        end

        private

        delegate :export_metrics?,
          :save_metrics_json?,
          :ci_job_url,
          :ci_job_name,
          :rspec_retried?,
          :disable_rspec_retry?,
          to: "QA::Runtime::Env"

        # Save execution data for the run
        #
        # @param [Array<RSpec::Core::Example>] examples
        # @return [Array<Hash>]
        def execution_data(examples = nil)
          @execution_metrics ||= examples.filter_map { |example| test_stats(example) }
        end
        alias_method :parse_execution_data, :execution_data

        # Push test execution metrics to influxdb
        #
        # @return [void]
        def push_test_metrics
          return log(:debug, "Metrics export not enabled, skipping test metrics export") unless export_metrics?

          write_api.write(data: execution_data)
          log(:debug, "Pushed #{execution_data.length} test execution entries to influxdb")
        rescue StandardError => e
          log(:error, "Failed to push test execution metrics to influxdb, error: #{e}")
        end

        # Push resource fabrication metrics to influxdb
        #
        # @return [void]
        def push_fabrication_metrics
          return log(:debug, "Metrics export not enabled, skipping fabrication metrics export") unless export_metrics?

          data = Tools::TestResourceDataProcessor.resources.flat_map do |resource, values|
            values.map { |v| fabrication_stats(resource: resource, **v) }
          end
          return if data.empty?

          write_api.write(data: data)
          log(:debug, "Pushed #{data.length} resource fabrication entries to influxdb")
        rescue StandardError => e
          log(:error, "Failed to push fabrication metrics to influxdb, error: #{e}")
        end

        # Save metrics in json file
        #
        # @return [void]
        def save_test_metrics
          return log(:debug, "Saving test metrics json not enabled, skipping") unless save_metrics_json?

          file = "tmp/test-metrics-#{env('CI_JOB_NAME_SLUG') || 'local'}-retry-#{rspec_retried?}.json"
          File.write(file, execution_data.to_json) && log(:debug, "Saved test metrics to #{file}")
        rescue StandardError => e
          log(:error, "Failed to save test execution metrics, error: #{e}")
        end

        # Transform example to influxdb compatible metrics data
        # https://github.com/influxdata/influxdb-client-ruby#data-format
        #
        # @param [RSpec::Core::Example] example
        # @return [Hash]
        def test_stats(example)
          # do not save failures from initial non retry run, as they will be retried and become flaky or failed
          return if disable_rspec_retry? && (!rspec_retried? && example.execution_result.status == :failed)

          {
            name: 'test-stats',
            time: time,
            tags: tags(example),
            fields: fields(example)
          }
        rescue StandardError => e
          log(:error, "Failed to transform example '#{example.id}', error: #{e}")
          nil
        end

        # Metrics tags
        #
        # @param [RSpec::Core::Example] example
        # @return [Hash]
        def tags(example)
          # use rerun_file_path so shared_examples have the correct file path
          file_path = example.metadata[:rerun_file_path].gsub('./qa/specs/features', '')

          {
            name: example.full_description,
            file_path: file_path,
            status: status(example),
            smoke: example.metadata.key?(:smoke).to_s,
            reliable: example.metadata.key?(:reliable).to_s,
            blocking: example.metadata.key?(:blocking).to_s,
            quarantined: quarantined(example),
            job_name: job_name,
            merge_request: merge_request,
            run_type: run_type,
            stage: devops_stage(file_path),
            product_group: example.metadata[:product_group],
            testcase: example.metadata[:testcase],
            exception_class: example.execution_result.exception&.class&.to_s,
            **custom_metrics_tags(example.metadata)
          }.compact
        end

        # Metrics fields
        #
        # @param [RSpec::Core::Example] example
        # @return [Hash]
        def fields(example)
          api_fabrication = ((example.metadata[:api_fabrication] || 0) * 1000).round
          ui_fabrication = ((example.metadata[:browser_ui_fabrication] || 0) * 1000).round

          {
            id: example.id,
            run_time: (example.execution_result.run_time * 1000).round,
            api_fabrication: api_fabrication,
            ui_fabrication: ui_fabrication,
            total_fabrication: api_fabrication + ui_fabrication,
            job_url: ci_job_url,
            pipeline_url: env('CI_PIPELINE_URL'),
            pipeline_id: env('CI_PIPELINE_ID'),
            job_id: env('CI_JOB_ID'),
            merge_request_iid: merge_request_iid,
            failure_exception: example.execution_result.exception.to_s.delete("\n"),
            **custom_metrics_fields(example.metadata)
          }.compact
        end

        # Resource fabrication data point
        #
        # @param [String] resource
        # @param [String] info
        # @param [Symbol] fabrication_method
        # @param [Symbol] http_method
        # @param [Integer] fabrication_time
        # @param [String] timestamp
        # @return [Hash]
        def fabrication_stats(resource:, info:, fabrication_method:, http_method:, fabrication_time:, timestamp:, **)
          {
            name: 'fabrication-stats',
            time: time,
            tags: {
              resource: resource,
              fabrication_method: fabrication_method,
              http_method: http_method,
              run_type: run_type,
              merge_request: merge_request
            },
            fields: {
              fabrication_time: fabrication_time,
              info: info,
              job_url: ci_job_url,
              timestamp: timestamp
            }
          }
        end

        # Base ci job name
        #
        # @return [String]
        def job_name
          @job_name ||= ci_job_name&.gsub(%r{ \d{1,2}/\d{1,2}}, '')
        end

        # Single common timestamp for all exported example metrics to keep data points consistently grouped
        #
        # @return [Time]
        def time
          @time ||= env('CI_PIPELINE_CREATED_AT')&.to_time || Time.now
        end

        # Is a merge request execution
        #
        # @return [String]
        def merge_request
          (!!merge_request_iid).to_s
        end

        # Is spec quarantined
        #
        # @param [RSpec::Core::Example] example
        # @return [String]
        def quarantined(example)
          return "false" unless example.metadata.key?(:quarantine)

          # if quarantine key is present and status is pending, consider it quarantined
          (example.execution_result.status == :pending).to_s
        end

        # Return a more detailed status
        #
        # - if test is failed or pending, return rspec status
        # - if test passed but had more than 1 attempt, consider test flaky
        #
        # @param [RSpec::Core::Example] example
        # @return [Symbol]
        def status(example)
          rspec_status = example.execution_result.status
          return rspec_status if [:pending, :failed].include?(rspec_status)
          # if rspec-retry gem is disabled, check for rspec retry process
          return rspec_retried? && rspec_status == :passed ? :flaky : :passed if disable_rspec_retry?

          retry_attempts(example.metadata) > 0 ? :flaky : :passed
        end

        # Retry attempts
        #
        # @param [Hash] metadata
        # @return [Integer]
        def retry_attempts(metadata)
          metadata[:retry_attempts] || 0
        end

        # Additional custom metrics tags
        #
        # @param [Hash] metadata
        # @return [Hash]
        def custom_metrics_tags(metadata)
          custom_metrics(metadata, :tags)
        end

        # Additional custom metrics fields
        #
        # @param [Hash] metadata
        # @return [Hash]
        def custom_metrics_fields(metadata)
          custom_metrics(metadata, :fields)
        end

        # Custom test metrics
        #
        # @param [Hash] metadata
        # @param [Symbol] type type of metric, :fields or :tags
        # @return [Hash]
        def custom_metrics(metadata, type)
          custom_metrics = metadata[CUSTOM_METRICS_KEY]
          return {} unless custom_metrics
          return {} unless custom_metrics.is_a?(Hash) && custom_metrics[type].is_a?(Hash)

          custom_metrics[type].to_h do |key, value|
            k = key.to_sym
            v = value.is_a?(Numeric) || value.nil? ? value : value.to_s

            [k, v]
          end
        end

        # Get spec devops stage
        #
        # @param [String] location
        # @return [String, nil]
        def devops_stage(file_path)
          file_path.match(%r{\d{1,2}_(\w+)/})&.captures&.first
        end

        # Print log message
        #
        # @param [Symbol] level
        # @param [String] message
        # @return [void]
        def log(level, message)
          QA::Runtime::Logger.public_send(level, "[influxdb exporter]: #{message}")
        end
      end
    end
  end
end
