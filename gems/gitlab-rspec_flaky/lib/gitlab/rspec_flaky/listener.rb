# frozen_string_literal: true

require 'json'

require_relative 'config'
require_relative 'example'
require_relative 'flaky_example'
require_relative 'flaky_examples_collection'
require_relative 'report'

module Gitlab
  module RspecFlaky
    class Listener
      # - suite_flaky_examples: contains all the currently tracked flacky example
      #   for the whole RSpec suite
      # - flaky_examples: contains the examples detected as flaky during the
      #   current RSpec run
      attr_reader :suite_flaky_examples, :flaky_examples

      def initialize(suite_flaky_examples_json = nil)
        @flaky_examples = FlakyExamplesCollection.new
        @suite_flaky_examples = init_suite_flaky_examples(suite_flaky_examples_json)
      end

      def example_passed(notification)
        current_example = Example.new(notification.example)

        return unless current_example.attempts > 1

        flaky_example = suite_flaky_examples.fetch(current_example.uid) do
          FlakyExample.new(current_example.to_h)
        end
        flaky_example.update!(current_example.to_h)

        flaky_examples[current_example.uid] = flaky_example
      end

      def dump_summary(_)
        rails_logger_warn(
          "\n#{flaky_examples.count} known flaky example(s) detected. " \
          "Writing this to #{Config.flaky_examples_report_path}.\n"
        )
        Report.new(flaky_examples).write(Config.flaky_examples_report_path)

        return unless new_flaky_examples.any?

        rails_logger_warn("\nNew flaky examples detected:\n")
        rails_logger_warn(JSON.pretty_generate(new_flaky_examples.to_h))

        Report.new(new_flaky_examples).write(Config.new_flaky_examples_report_path)
      end

      private

      def new_flaky_examples
        @new_flaky_examples ||= flaky_examples - suite_flaky_examples
      end

      def init_suite_flaky_examples(suite_flaky_examples_json = nil)
        if suite_flaky_examples_json
          Report.load_json(suite_flaky_examples_json).flaky_examples
        else
          return {} unless File.exist?(Config.suite_flaky_examples_report_path)

          Report.load(Config.suite_flaky_examples_report_path).flaky_examples
        end
      end

      def rails_logger_warn(text)
        target = defined?(Rails) ? Rails.logger : Kernel

        target.warn(text)
      end
    end
  end
end
