# frozen_string_literal: true

require_relative '../helpers'

# Entrypoint for flow to print examples of how to trigger an
# event in different languages & different methods of testing
module InternalEventsCli
  module Flows
    class UsageViewer
      include Helpers

      PROPERTY_EXAMPLES = {
        'label' => "'string'",
        'property' => "'string'",
        'value' => '72',
        'custom_key' => 'custom_value'
      }.freeze

      attr_reader :cli, :event

      def initialize(cli, event_path = nil, event = nil)
        @cli = cli
        @event = event
        @selected_event_path = event_path
      end

      def run
        prompt_for_eligible_event
        prompt_for_usage_location
      end

      def prompt_for_eligible_event
        return if event

        event_details = events_by_filepath

        @selected_event_path = cli.select(
          "Show examples for which event?",
          get_event_options(event_details),
          **select_opts,
          **filter_opts
        )

        @event = event_details[@selected_event_path]
      end

      def prompt_for_usage_location(default = '1. ruby/rails')
        choices = [
          { name: '1. ruby/rails', value: :rails },
          { name: '2. rspec', value: :rspec },
          { name: '3. javascript (vue)', value: :vue },
          { name: '4. javascript (plain)', value: :js },
          { name: '5. vue template', value: :vue_template },
          { name: '6. haml', value: :haml },
          { name: '7. Manual testing in GDK', value: :gdk },
          { name: '8. Data verification in Tableau', value: :tableau },
          { name: '9. View examples for a different event', value: :other_event },
          { name: '10. Exit', value: :exit }
        ]

        usage_location = cli.select(
          'Select a use-case to view examples for:',
          choices,
          **select_opts,
          **filter_opts,
          per_page: 10
        ) do |menu|
          menu.default default
        end

        case usage_location
        when :rails
          rails_examples
          prompt_for_usage_location('1. ruby/rails')
        when :rspec
          rspec_examples
          prompt_for_usage_location('2. rspec')
        when :haml
          haml_examples
          prompt_for_usage_location('6. haml')
        when :js
          js_examples
          prompt_for_usage_location('4. javascript (plain)')
        when :vue
          vue_examples
          prompt_for_usage_location('3. javascript (vue)')
        when :vue_template
          vue_template_examples
          prompt_for_usage_location('5. vue template')
        when :gdk
          gdk_examples
          prompt_for_usage_location('7. Manual testing in GDK')
        when :tableau
          service_ping_dashboard_examples
          prompt_for_usage_location('8. Data verification in Tableau')
        when :other_event
          self.class.new(cli).run
        when :exit
          cli.say(feedback_notice)
        end
      end

      def rails_examples
        identifier_args = identifiers.map do |identifier|
          "  #{identifier}: #{identifier}"
        end

        property_args = format_additional_properties do |property, value, description|
          "    #{property}: #{value}, # #{description}"
        end

        if property_args.any?
          # remove trailing comma after last arg but keep any other commas
          property_args.last.sub!(',', '')
          property_arg = "  additional_properties: {\n#{property_args.join("\n")}\n  }"
        end

        args = ["'#{action}'", *identifier_args, property_arg].compact.join(",\n")
        args = "\n  #{args}\n" if args.lines.count > 1

        cli.say format_warning <<~TEXT
          #{divider}
          #{format_help('# RAILS')}

          include Gitlab::InternalEventsTracking

          track_internal_event(#{args})

          #{divider}
        TEXT
      end

      def rspec_examples
        identifier_args = identifiers.map do |identifier|
          "  let(:#{identifier}) { create(:#{identifier}) }\n"
        end.join('')

        property_args = format_additional_properties do |property, value|
          "    #{property}: #{value}"
        end

        if property_args.any?
          property_arg = format_prefix '  ', <<~TEXT
            let(:additional_properties) do
              {
            #{property_args.join(",\n")}
              }
            end
          TEXT
        end

        args = [*identifier_args, *property_arg].join('')

        cli.say format_warning <<~TEXT
          #{divider}
          #{format_help('# RSPEC')}

          it_behaves_like 'internal event tracking' do
            let(:event) { '#{action}' }
            let(:category) { described_class.name }
          #{args}end

          #{divider}
        TEXT
      end

      def haml_examples
        property_args = format_additional_properties do |property, value, _|
          "event_#{property}: #{value}"
        end

        args = ["event_tracking: '#{action}'", *property_args].join(', ')

        cli.say <<~TEXT
          #{divider}
          #{format_help('# HAML -- ON-CLICK')}

          .inline-block{ #{format_warning("data: { #{args} }")} }
            = _('Important Text')

          #{divider}
          #{format_help('# HAML -- COMPONENT ON-CLICK')}

          = render Pajamas::ButtonComponent.new(button_options: { #{format_warning("data: { #{args} }")} })

          #{divider}
          #{format_help('# HAML -- COMPONENT ON-LOAD')}

          = render Pajamas::ButtonComponent.new(button_options: { #{format_warning("data: { event_tracking_load: true, #{args} }")} })

          #{divider}
        TEXT

        cli.say("Want to see the implementation details? See app/assets/javascripts/tracking/internal_events.js\n\n")
      end

      def vue_template_examples
        on_click_args = template_formatted_args('data-event-tracking', indent: 2)
        on_load_args = template_formatted_args('data-event-tracking-load', indent: 2)

        cli.say <<~TEXT
          #{divider}
          #{format_help('// VUE TEMPLATE -- ON-CLICK')}

          <script>
          import { GlButton } from '@gitlab/ui';

          export default {
            components: { GlButton }
          };
          </script>

          <template>
            <gl-button#{on_click_args}
              Click Me
            </gl-button>
          </template>

          #{divider}
          #{format_help('// VUE TEMPLATE -- ON-LOAD')}

          <script>
          import { GlButton } from '@gitlab/ui';

          export default {
            components: { GlButton }
          };
          </script>

          <template>
            <gl-button#{on_load_args}
              Click Me
            </gl-button>
          </template>

          #{divider}
        TEXT

        cli.say("Want to see the implementation details? See app/assets/javascripts/tracking/internal_events.js\n\n")
      end

      def js_examples
        args = js_formatted_args(indent: 2)

        cli.say <<~TEXT
          #{divider}
          #{format_help('// FRONTEND -- RAW JAVASCRIPT')}

          #{format_warning("import { InternalEvents } from '~/tracking';")}

          export const performAction = () => {
            #{format_warning("InternalEvents.trackEvent#{args}")}

            return true;
          };

          #{divider}
        TEXT

        # https://docs.snowplow.io/docs/understanding-your-pipeline/schemas/
        cli.say("Want to see the implementation details? See app/assets/javascripts/tracking/internal_events.js\n\n")
      end

      def vue_examples
        args = js_formatted_args(indent: 6)

        cli.say <<~TEXT
          #{divider}
          #{format_help('// VUE')}

          <script>
          #{format_warning("import { InternalEvents } from '~/tracking';")}
          import { GlButton } from '@gitlab/ui';

          #{format_warning('const trackingMixin = InternalEvents.mixin();')}

          export default {
            #{format_warning('mixins: [trackingMixin]')},
            components: { GlButton },
            methods: {
              performAction() {
                #{format_warning("this.trackEvent#{args}")}
              },
            },
          };
          </script>

          <template>
            <gl-button @click=performAction>Click Me</gl-button>
          </template>

          #{divider}
        TEXT

        cli.say("Want to see the implementation details? See app/assets/javascripts/tracking/internal_events.js\n\n")
      end

      private

      def action
        event['action']
      end

      def identifiers
        Array(event['identifiers']).tap do |ids|
          # We always auto assign namespace if project is provided
          ids.delete('namespace') if ids.include?('project')
        end
      end

      def additional_properties
        Array(event['additional_properties'])
      end

      def format_additional_properties
        additional_properties.map do |property, details|
          example_value = PROPERTY_EXAMPLES[property]
          description = details['description'] || 'TODO'

          yield(property, example_value, description)
        end
      end

      def js_formatted_args(indent:)
        return "('#{action}');" if additional_properties.none?

        property_args = format_additional_properties do |property, value, description|
          "    #{property}: #{value}, // #{description}"
        end

        [
          '(',
          "  '#{action}',",
          '  {',
          *property_args,
          '  },',
          ');'
        ].join("\n#{' ' * indent}")
      end

      def service_ping_metrics_info
        product_group = related_metrics.map(&:product_group).uniq

        <<~TEXT
          #{product_group.map { |group| "#{group}: #{format_info(metric_exploration_group_path(group, find_stage(group)))}" }.join("\n")}

          #{divider}
          #{format_help("# METRIC TRENDS -- view data for a service ping metric for #{event.action}")}

          #{related_metrics.map { |metric| "#{metric.key_path}: #{format_info(metric_trend_path(metric.key_path))}" }.join("\n")}
        TEXT
      end

      def service_ping_no_metric_info
        <<~TEXT
          #{format_help("# Warning: There are no metrics for #{event.action} yet.")}
          #{event.product_group}: #{format_info(metric_exploration_group_path(event.product_group, find_stage(event.product_group)))}
        TEXT
      end

      def template_formatted_args(data_attr, indent:)
        return " #{data_attr}=\"#{action}\">" if additional_properties.none?

        spacer = ' ' * indent
        property_args = format_additional_properties do |property, value, _|
          "  data-event-#{property}=#{value.tr("'", '"')}"
        end

        args = [
          '', # start args on next line
          "  #{data_attr}=\"#{action}\"",
          *property_args
        ].join("\n#{spacer}")

        "#{format_warning(args)}\n#{spacer}>"
      end

      def related_metrics
        cli.global.metrics.select { |metric| metric.actions&.include?(event.action) }
      end

      def service_ping_dashboard_examples
        cli.say <<~TEXT
          #{divider}
          #{format_help('# GROUP DASHBOARDS -- view all service ping metrics for a specific group')}

          #{related_metrics.any? ? service_ping_metrics_info : service_ping_no_metric_info}
          #{divider}
          Note: The metric dashboard links can also be accessed from #{format_info('https://metrics.gitlab.com/')}

          Not what you're looking for? Check this doc:
            - #{format_info('https://docs.gitlab.com/ee/development/internal_analytics/#data-discovery')}

        TEXT
      end

      def gdk_examples
        key_paths = related_metrics.map(&:key_path)

        cli.say <<~TEXT
          #{divider}
          #{format_help('# TERMINAL -- monitor events & changes to service ping metrics as they occur')}

          1. From `gitlab/` directory, run the monitor script:

          #{format_warning("bin/rails runner scripts/internal_events/monitor.rb #{event.action}")}

          2. View metric updates within the terminal

          3. [Optional] Configure gdk with snowplow micro to see individual events: https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/snowplow_micro.md

          #{divider}
          #{format_help('# RAILS CONSOLE -- generate service ping payload, including most recent usage data')}

          #{format_warning("require_relative 'spec/support/helpers/service_ping_helpers.rb'")}

          #{format_help('# Get current value of a metric')}
          #{
            if key_paths.any?
              key_paths.map { |key_path| format_warning("ServicePingHelpers.get_current_usage_metric_value('#{key_path}')") }.join("\n")
            else
              format_help("# Warning: There are no metrics for #{event.action} yet. When there are, replace <key_path> below.\n") +
              format_warning('ServicePingHelpers.get_current_usage_metric_value(<key_path>)')
            end
          }

          #{format_help('# View entire service ping payload')}
          #{format_warning('ServicePingHelpers.get_current_service_ping_payload')}
          #{divider}
          Need to test something else? Check these docs:
          - https://docs.gitlab.com/ee/development/internal_analytics/internal_event_instrumentation/local_setup_and_debugging.html
          - https://docs.gitlab.com/ee/development/internal_analytics/service_ping/troubleshooting.html
          - https://docs.gitlab.com/ee/development/internal_analytics/review_guidelines.html

        TEXT
      end
    end
  end
end
