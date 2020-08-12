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

      def stop(notification)
        # Based on https://github.com/rspec/rspec-core/blob/main/lib/rspec/core/formatters/json_formatter.rb#L35
        # But modified to include full details of multiple exceptions
        @output_hash[:examples] = notification.examples.map do |example|
          format_example(example).tap do |hash|
            e = example.exception
            if e
              exceptions = e.respond_to?(:all_exceptions) ? e.all_exceptions : [e]
              hash[:exceptions] = exceptions.map do |exception|
                {
                  class: exception.class.name,
                  message: exception.message,
                  backtrace: exception.backtrace
                }
              end
            end
          end
        end
      end

      private

      def format_example(example)
        {
          id: example.id,
          description: example.description,
          full_description: example.full_description,
          status: example.execution_result.status.to_s,
          file_path: example.metadata[:file_path],
          line_number: example.metadata[:line_number],
          run_time: example.execution_result.run_time,
          pending_message: example.execution_result.pending_message,
          status_issue: example.metadata[:status_issue],
          quarantine: example.metadata[:quarantine],
          screenshot: example.metadata[:screenshot]
        }
      end
    end
  end
end
