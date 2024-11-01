# frozen_string_literal: true

require_relative '../helpers'
require_relative '../text/flow_advisor'

# Entrypoint for help flow, which directs the user to the
# correct flow or documentation based on their goal
module InternalEventsCli
  module Flows
    class FlowAdvisor
      include Helpers
      include Text::FlowAdvisor

      attr_reader :cli

      def initialize(cli)
        @cli = cli
      end

      def run
        return use_case_error unless goal_is_tracking_usage?
        return use_case_error unless usage_trackable_with_internal_events?

        event_already_tracked? ? proceed_to_metric_definition : proceed_to_event_definition
      end

      private

      def goal_is_tracking_usage?
        new_page!

        cli.say format_info("First, let's check your objective.\n")

        cli.yes?('Are you trying to track customer usage of a GitLab feature?', **yes_no_opts)
      end

      def usage_trackable_with_internal_events?
        new_page!

        cli.say format_info("Excellent! Let's check that this tool will fit your needs.\n")
        cli.say EVENT_TRACKING_EXAMPLES

        cli.yes?(
          'Can usage for the feature be measured with a count of specific user actions or events? ' \
            'Or counting a set of events?',
          **yes_no_opts
        )
      end

      def event_already_tracked?
        new_page!

        cli.say format_info("Super! Let's figure out if the event is already tracked & usable.\n")
        cli.say EVENT_EXISTENCE_CHECK_INSTRUCTIONS

        cli.yes?('Is the event already tracked?', **yes_no_opts)
      end

      def use_case_error
        new_page!

        cli.error("Oh no! This probably isn't the tool you need!\n")
        cli.say ALTERNATE_RESOURCES_NOTICE
        cli.say feedback_notice
      end

      def proceed_to_metric_definition
        new_page!

        cli.say format_info("Amazing! The next step is adding a new metric! (~8-15 min)\n")

        return not_ready_error('New Metric') unless cli.yes?(format_prompt('Ready to start?'))

        MetricDefiner.new(cli).run
      end

      def proceed_to_event_definition
        new_page!

        cli.say format_info("Okay! The next step is adding a new event! (~5-10 min)\n")

        return not_ready_error('New Event') unless cli.yes?(format_prompt('Ready to start?'))

        EventDefiner.new(cli).run
      end

      def not_ready_error(description)
        cli.say "\nNo problem! When you're ready, run the CLI & select '#{description}'\n"
        cli.say feedback_notice
      end
    end
  end
end
