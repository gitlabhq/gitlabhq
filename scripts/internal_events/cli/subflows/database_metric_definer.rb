# frozen_string_literal: true

module InternalEventsCli
  module Subflows
    class DatabaseMetricDefiner
      include Helpers
      include Text::MetricDefiner

      CLASS_NAME_REGEX = /\A[a-zA-Z]+\z/

      attr_reader :metric

      def initialize(cli)
        @cli = cli
        @metric = nil
      end

      def run
        @metric = Metric.new
        metric.data_source = 'database'

        prompt_for_instrumentation_class
        prompt_for_time_frame
      end

      private

      attr_reader :cli

      def prompt_for_instrumentation_class
        cli.say INSTRUMENTATION_CLASS_INTRO
        cli.say <<~TEXT

          #{input_opts[:prefix]} What should be the instrumentation class for this metric? #{input_required_text}

        TEXT

        metric.instrumentation_class = prompt_for_text('  Instrumentation class: ') do |q|
          q.required true
          q.messages[:required?] = INSTRUMENTATION_CLASS_HELP
          q.messages[:valid?] = INSTRUMENTATION_CLASS_ERROR
          q.validate ->(input) { input.match?(CLASS_NAME_REGEX) }
        end
      end

      def prompt_for_time_frame
        metric.time_frame = cli.multi_select(
          'For which time frames do you want the metric to be calculated? (Space to select)',
          time_frame_options,
          **multiselect_opts,
          **filter_opts(header_size: 7)
        )
      end

      def time_frame_options
        [
          {
            name: "Weekly",
            value: '7d'
          }, {
            name: "Monthly",
            value: '28d'
          }, {
            name: "Total (no time restriction)",
            value: 'all'
          }
        ]
      end
    end
  end
end
