# frozen_string_literal: true

require 'rspec/core/formatters'

module QA
  module Support
    class JsonFormatter < RSpec::Core::Formatters::JsonFormatter
      RSpec::Core::Formatters.register self, :message, :dump_summary, :stop, :seed, :close

      def dump_profile(profile)
        # We don't currently use the profile info. This overrides the base
        # implementation so that it's not included.
      end

      def stop(example_notification)
        # Based on https://github.com/rspec/rspec-core/blob/main/lib/rspec/core/formatters/json_formatter.rb#L35
        # But modified to include full details of multiple exceptions and to provide output similar to
        # https://github.com/sj26/rspec_junit_formatter
        @output_hash[:examples] = example_notification.notifications.filter_map do |notification|
          format_example(notification)
        end
      end

      private

      def format_example(notification)
        example = notification.example

        # Remove failures from initial run if retry is enabled
        return if initial_rspec_run? && example.execution_result.status == :failed

        file_path, line_number = location_including_shared_examples(example.metadata)

        data = {
          id: example.id,
          description: example.description,
          full_description: example.full_description,
          status: example.execution_result.status.to_s,
          file_path: file_path,
          line_number: line_number.to_i,
          run_time: example.execution_result.run_time,
          pending_message: example.execution_result.pending_message,
          testcase: example.metadata[:testcase],
          quarantine: example.metadata[:quarantine],
          screenshot: example.metadata[:screenshot],
          product_group: example.metadata[:product_group],
          ci_job_url: QA::Runtime::Env.ci_job_url,
          level: 'E2E',
          ignore_runtime_data: Runtime::Env.ignore_runtime_data?
        }

        e = example.exception
        return data unless e

        exceptions = e.respond_to?(:all_exceptions) ? e.all_exceptions : [e]
        data.merge({
          exceptions: exceptions.map do |exception|
            {
              class: exception.class.name,
              message: exception.message,
              message_lines: strip_ansi_codes(notification.message_lines),
              correlation_id: exception.message[match_data_after(Loglinking::CORRELATION_ID_TITLE)],
              sentry_url: exception.message[match_data_after(Loglinking::SENTRY_URL_TITLE)],
              kibana_discover_url: exception.message[match_data_after(Loglinking::KIBANA_DISCOVER_URL_TITLE)],
              kibana_dashboard_url: exception.message[match_data_after(Loglinking::KIBANA_DASHBOARD_URL_TITLE)],
              backtrace: notification.formatted_backtrace
            }
          end
        })
      end

      def location_including_shared_examples(metadata)
        if metadata[:shared_group_inclusion_backtrace].empty?
          [metadata[:file_path], metadata[:line_number]]
        else
          # If there are nested shared examples, the outermost location is last in the array
          metadata[:shared_group_inclusion_backtrace].last.formatted_inclusion_location.split(':')
        end
      end

      def strip_ansi_codes(strings)
        # The code below is from https://github.com/piotrmurach/pastel/blob/master/lib/pastel/color.rb
        modified = Array(strings).map { |string| string.dup.gsub(/\x1b\[{1,2}[0-9;:?]*m/m, '') }
        modified.size == 1 ? modified[0] : modified
      end

      def match_data_after(title)
        /(?<=#{title} ).*/
      end

      def initial_rspec_run?
        ::Gitlab::QA::Runtime::Env.retry_failed_specs? && !Runtime::Env.rspec_retried?
      end
    end
  end
end
