# frozen_string_literal: true

require "active_support/core_ext/string/conversions"

module QA
  module Support
    module Formatters
      class TestMetricsFormatter < RSpec::Core::Formatters::BaseFormatter
        include Support::InfluxdbTools
        include Support::GcsTools
        include Support::Repeater
        include Support::Retrier

        CUSTOM_METRICS_KEY = :custom_test_metrics

        RSpec::Core::Formatters.register(self, :stop)

        # Finish test execution
        #
        # @param [RSpec::Core::Notifications::ExamplesNotification] notification
        # @return [void]
        def stop(notification)
          return log(:warn, "Missing run_type, skipping metrics export!") unless run_type

          parse_execution_data(notification.examples)

          export_test_metrics
          save_test_metrics
        end

        private

        delegate :export_metrics?,
          :save_metrics_json?,
          :ci_job_url,
          :ci_job_name,
          :rspec_retried?,
          :parallel_run?,
          to: QA::Runtime::Env

        delegate :retry_failed_specs?, to: ::Gitlab::QA::Runtime::Env

        # Save execution data for the run
        #
        # @param [Array<RSpec::Core::Example>] examples
        # @return [Array<Hash>]
        def execution_data(examples = nil)
          @execution_metrics ||= examples.filter_map { |example| test_stats(example) }
        end

        alias_method :parse_execution_data, :execution_data

        # Export metrics directly to InfluxDb or GCS bucket
        #
        # @return [void]
        def export_test_metrics
          return log(:info, "Exporting test metrics to not enabled, skipping ") unless export_metrics?

          push_test_metrics
          push_fabrication_metrics
          push_code_runtime_metrics
        end

        # Save metrics in json file
        #
        # @return [void]
        def save_test_metrics
          return log(:info, "Saving test metrics json not enabled, skipping") unless save_metrics_json?

          file = File.join('tmp', metrics_file_name(prefix: 'test', with_pipeline_id_postfix: false))

          File.write(file, execution_data.to_json) && log(:debug, "Saved test metrics to #{file}")
        rescue StandardError => e
          log(:error, "Failed to save test execution metrics, error: #{e}")
        end

        # Upload test execution metrics
        #
        # @return [void]
        def push_test_metrics
          push_test_metrics_to_influxdb
          push_test_metrics_to_gcs
        end

        # Push test execution metrics to InfluxDB
        #
        # @return [void]
        def push_test_metrics_to_influxdb
          write_api.write(data: execution_data)
          log(:info, "Pushed #{execution_data.length} test execution entries to influxdb")
        rescue StandardError => e
          log(:error, "Failed to push test execution metrics to influxdb, error: #{e}")
        end

        # Push test execution metrics to GCS
        #
        # @return [void]
        def push_test_metrics_to_gcs
          init_gcs_client! # init client and exit early if mandatory configuration is missing
          retry_on_exception(sleep_interval: 30, message: 'Failed to push test metrics to GCS') do
            gcs_client.put_object(
              gcs_bucket,
              metrics_file_name(prefix: 'test'),
              execution_data.to_json,
              force: true, content_type: 'application/json'
            )

            log(:info, "Pushed #{execution_data.length} test execution entries to GCS")
          end
        rescue StandardError => e
          log(:error, "Failed to push test execution metrics to gcs, error: #{e}")
        end

        # Push resource fabrication metrics to influxdb
        #
        # @return [void]
        def push_fabrication_metrics
          data = Tools::TestResourceDataProcessor.resources.flat_map do |resource, values|
            values.map { |v| fabrication_stats(resource: resource, **v) }
          end

          return if data.empty?

          push_fabrication_metrics_influxdb(data)
          push_fabrication_metrics_gcs(data)
        end

        # Push code runtime metrics to influxdb
        #
        # @return [void]
        def push_code_runtime_metrics
          return if method_call_data.empty?

          write_api.write(data: method_call_data)
          log(:info, "Pushed #{method_call_data.length} code runtime entries to influxdb")
        rescue StandardError => e
          log(:error, "Failed to push code runtime metrics to influxdb, error: #{e}")
        end

        # Push resource fabrication metrics to GCS
        #
        # @param [Hash] data fabrication data hash
        # @return [void]
        def push_fabrication_metrics_gcs(data)
          init_gcs_client! # init client and exit early if mandatory configuration is missing
          retry_on_exception(sleep_interval: 30, message: 'Failed to push resource fabrication metrics to GCS') do
            gcs_client.put_object(
              gcs_bucket,
              metrics_file_name(prefix: 'fabrication'),
              data.to_json, force: true,
              content_type: 'application/json'
            )

            log(:info, "Pushed #{data.length} resource fabrication entries to GCS")
          end
        rescue StandardError => e
          log(:error, "Failed to push test fabrication metrics to gcs, error: #{e}")
        end

        # Push resource fabrication metrics to InfluxDB
        #
        # @param [Hash] data fabrication data hash
        # @return [void]
        def push_fabrication_metrics_influxdb(data)
          write_api.write(data: data)
          log(:info, "Pushed #{data.length} resource fabrication entries to influxdb")
        rescue StandardError => e
          log(:error, "Failed to push fabrication metrics to influxdb, error: #{e}")
        end

        # Init client raising error if configuration variables are missing
        #
        # @return [void]
        def init_gcs_client!
          gcs_client || gcs_bucket
        end

        # Get GCS Bucket Name or raise error if missing
        #
        # @return [String]
        def gcs_bucket
          @gcs_bucket ||= ENV['QA_METRICS_GCS_BUCKET_NAME'] ||
            raise('Missing QA_METRICS_GCS_BUCKET_NAME env variable')
        end

        # Construct file name for metrics
        #
        # @param [String] prefix
        # @param [Boolean] with_pipeline_id_postfix
        # @return [String]
        def metrics_file_name(prefix:, with_pipeline_id_postfix: true)
          name = ["#{prefix}-metrics-#{env('CI_JOB_NAME_SLUG') || 'local'}"]
          name << "-env-#{env('TEST_ENV_NUMBER') || 1}" if parallel_run?
          name << "-retry-#{rspec_retried?}" if retry_failed_specs?
          name << "-#{env('CI_PIPELINE_ID') || 'local'}" if with_pipeline_id_postfix
          name << ".json"

          name.join
        end

        # Transform example to influxdb compatible metrics data
        # https://github.com/influxdata/influxdb-client-ruby#data-format
        #
        # @param [RSpec::Core::Example] example
        # @return [Hash]
        def test_stats(example)
          # do not save failures from initial non retry run, as they will be retried and become flaky or failed
          return if retry_failed_specs? && (!rspec_retried? && example.execution_result.status == :failed)

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
            quarantined: quarantined(example),
            job_name: job_name,
            merge_request: merge_request,
            run_type: run_type,
            stage: devops_stage(file_path),
            product_group: example.metadata[:product_group],
            testcase: example.metadata[:testcase],
            exception_class: example.execution_result.exception&.class&.to_s,
            branch: branch,
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
            pipeline_url: ci_pipeline_url,
            pipeline_id: env('CI_PIPELINE_ID'),
            job_id: env('CI_JOB_ID'),
            merge_request_iid: merge_request_iid,
            failure_exception: example.execution_result.exception.to_s.delete("\n"),
            location: example_location(example),
            failure_issue: example.metadata.dig(:quarantine, :issue),
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
              merge_request: merge_request,
              branch: branch
            }.compact,
            fields: {
              fabrication_time: fabrication_time,
              info: info,
              job_url: ci_job_url,
              pipeline_url: ci_pipeline_url,
              timestamp: timestamp
            }.compact
          }
        end

        # Data on method call and it's runtimes
        #
        # @return [Array]
        def method_call_data
          @method_call_data ||= CodeRuntimeTracker.method_call_data.flat_map do |name, params|
            params.map do |p|
              {
                name: 'method-call-stats',
                time: time,
                tags: {
                  method: name,
                  call_arg: p[:call_arg],
                  run_type: run_type,
                  merge_request: merge_request,
                  branch: branch
                }.compact,
                fields: {
                  runtime: (p[:runtime] * 1000).round,
                  job_url: ci_job_url,
                  pipeline_url: ci_pipeline_url,
                  filename: p[:filename]
                }.compact
              }
            end
          end
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

        # Pipeline url
        #
        # @return [String]
        def ci_pipeline_url
          @ci_pipeline_url ||= env('CI_PIPELINE_URL')
        end

        # Branch name
        #
        # @return [String]
        def branch
          @branch ||= env('CI_COMMIT_REF_NAME')
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

          rspec_retried? && rspec_status == :passed ? :flaky : :passed
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

        # Example location
        #
        # @param [RSpec::Core::Example] example
        # @return [String]
        def example_location(example)
          # ensures that location will be correct even in case of shared examples
          file = example
                 .metadata
                 .fetch(:shared_group_inclusion_backtrace)
                 .last
                 &.formatted_inclusion_location

          return example.location unless file

          file
        end
      end
    end
  end
end
