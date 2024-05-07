# frozen_string_literal: true

require_relative './helpers'

module InternalEventsCli
  class UsageViewer
    include Helpers

    IDENTIFIER_EXAMPLES = {
      %w[namespace project user] => { "namespace" => "project.namespace" },
      %w[namespace user] => { "namespace" => "group" }
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

    def prompt_for_usage_location(default = 'ruby/rails')
      choices = [
        { name: 'ruby/rails', value: :rails },
        { name: 'rspec', value: :rspec },
        { name: 'javascript (vue)', value: :vue },
        { name: 'javascript (plain)', value: :js },
        { name: 'vue template', value: :vue_template },
        { name: 'haml', value: :haml },
        { name: 'Manual testing in GDK', value: :gdk },
        { name: 'View examples for a different event', value: :other_event },
        { name: 'Exit', value: :exit }
      ]

      usage_location = cli.select(
        'Select a use-case to view examples for:',
        choices,
        **select_opts,
        per_page: 10
      ) do |menu|
        menu.enum '.'
        menu.default default
      end

      case usage_location
      when :rails
        rails_examples
        prompt_for_usage_location('ruby/rails')
      when :rspec
        rspec_examples
        prompt_for_usage_location('rspec')
      when :haml
        haml_examples
        prompt_for_usage_location('haml')
      when :js
        js_examples
        prompt_for_usage_location('javascript (plain)')
      when :vue
        vue_examples
        prompt_for_usage_location('javascript (vue)')
      when :vue_template
        vue_template_examples
        prompt_for_usage_location('vue template')
      when :gdk
        gdk_examples
        prompt_for_usage_location('Manual testing in GDK')
      when :other_event
        self.class.new(cli).run
      when :exit
        cli.say(Text::FEEDBACK_NOTICE)
      end
    end

    def rails_examples
      args = Array(event['identifiers']).map do |identifier|
        "  #{identifier}: #{identifier_examples[identifier]}"
      end
      action = args.any? ? "\n  '#{event['action']}',\n" : "'#{event['action']}'"

      cli.say format_warning <<~TEXT
        #{divider}
        #{format_help('# RAILS')}

        include Gitlab::InternalEventsTracking

        track_internal_event(#{action}#{args.join(",\n")}#{"\n" unless args.empty?})

        #{divider}
      TEXT
    end

    def rspec_examples
      cli.say format_warning <<~TEXT
        #{divider}
        #{format_help('# RSPEC')}

        it_behaves_like 'internal event tracking' do
          let(:event) { '#{event['action']}' }
        #{
          Array(event['identifiers']).map do |identifier|
            "  let(:#{identifier}) { #{identifier_examples[identifier]} }\n"
          end.join('')
        }end

        #{divider}
      TEXT
    end

    def identifier_examples
      event['identifiers']
        .to_h { |identifier| [identifier, identifier] }
        .merge(IDENTIFIER_EXAMPLES[event['identifiers'].sort] || {})
    end

    def haml_examples
      cli.say <<~TEXT
        #{divider}
        #{format_help('# HAML -- ON-CLICK')}

        .gl-display-inline-block{ #{format_warning("data: { event_tracking: '#{event['action']}' }")} }
          = _('Important Text')

        #{divider}
        #{format_help('# HAML -- COMPONENT ON-CLICK')}

        = render Pajamas::ButtonComponent.new(button_options: { #{format_warning("data: { event_tracking: '#{event['action']}' }")} })

        #{divider}
        #{format_help('# HAML -- COMPONENT ON-LOAD')}

        = render Pajamas::ButtonComponent.new(button_options: { #{format_warning("data: { event_tracking_load: true, event_tracking: '#{event['action']}' }")} })

        #{divider}
      TEXT

      cli.say("Want to see the implementation details? See app/assets/javascripts/tracking/internal_events.js\n\n")
    end

    def vue_template_examples
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
          <gl-button #{format_warning("data-event-tracking=\"#{event['action']}\"")}>
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
          <gl-button #{format_warning("data-event-tracking-load=\"#{event['action']}\"")}>
            Click Me
          </gl-button>
        </template>

        #{divider}
      TEXT

      cli.say("Want to see the implementation details? See app/assets/javascripts/tracking/internal_events.js\n\n")
    end

    def js_examples
      cli.say <<~TEXT
        #{divider}
        #{format_help('// FRONTEND -- RAW JAVASCRIPT')}

        #{format_warning("import { InternalEvents } from '~/tracking';")}

        export const performAction = () => {
          #{format_warning("InternalEvents.trackEvent('#{event['action']}');")}

          return true;
        };

        #{divider}
      TEXT

      # https://docs.snowplow.io/docs/understanding-your-pipeline/schemas/
      cli.say("Want to see the implementation details? See app/assets/javascripts/tracking/internal_events.js\n\n")
    end

    def vue_examples
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
              #{format_warning("this.trackEvent('#{event['action']}');")}
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

    def gdk_examples
      key_paths = get_existing_metrics_for_events([event]).map(&:key_path)

      cli.say <<~TEXT
        #{divider}
        #{format_help('# TERMINAL -- monitor events sent to snowplow & changes to service ping metrics as they occur')}

        1. Configure gdk with snowplow micro https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/snowplow_micro.md
        2. From `gitlab/` directory, run the monitor script:

        #{format_warning("bin/rails runner scripts/internal_events/monitor.rb #{event.action}")}

        3. View all snowplow events in the browser at http://localhost:9091/micro/all (or whichever hostname & port you configured)
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
