# frozen_string_literal: true

require_relative './helpers'

module InternalEventsCli
  class EventDefiner
    include Helpers

    SCHEMA = ::JSONSchemer.schema(Pathname('config/events/schema.json'))
    STEPS = [
      'New Event',
      'Description',
      'Name',
      'Context',
      'URL',
      'Group',
      'Tiers',
      'Save files'
    ].freeze

    IDENTIFIER_OPTIONS = {
      %w[project namespace user] => 'Use case: For project-level user actions ' \
                                    '(ex - issue_assignee_changed) [MOST COMMON]',
      %w[namespace user] => 'Use case: For namespace-level user actions (ex - epic_assigned_to_milestone)',
      %w[user] => 'Use case: For user-only actions (ex - admin_impersonated_user)',
      %w[project namespace] => 'Use case: For project-level events without user interaction ' \
                               '(ex - service_desk_request_received)',
      %w[namespace] => 'Use case: For namespace-level events without user interaction ' \
                       '(ex - stale_runners_cleaned_up)',
      %w[feature_enabled_by_namespace_ids user] => 'Use case: For user actions attributable to multiple namespaces ' \
                                                   '(ex - Code-Suggestions / Duo Pro)',
      %w[] => "Use case: For instance-level events without user interaction [LEAST COMMON]"
    }.freeze

    IDENTIFIER_FORMATTING_BUFFER = "[#{IDENTIFIER_OPTIONS.keys.map { |k| k.join(', ') }.max_by(&:length)}]".length

    attr_reader :cli, :event

    def initialize(cli)
      @cli = cli
      @event = Event.new(milestone: MILESTONE)
    end

    def run
      prompt_for_description
      prompt_for_action
      prompt_for_context
      prompt_for_url
      prompt_for_product_group
      prompt_for_tier

      outcome = create_event_file
      display_result(outcome)

      prompt_for_next_steps
    end

    private

    def prompt_for_description
      new_page!(1, 7, STEPS)
      cli.say Text::EVENT_DESCRIPTION_INTRO

      event.description = cli.ask("Describe what the event tracks: #{input_required_text}", **input_opts) do |q|
        q.required true
        q.modify :trim
        q.messages[:required?] = Text::EVENT_DESCRIPTION_HELP
      end
    end

    def prompt_for_action
      new_page!(2, 7, STEPS)
      cli.say Text::EVENT_ACTION_INTRO

      event.action = cli.ask("Define the event name: #{input_required_text}", **input_opts) do |q|
        q.required true
        q.validate ->(input) { input =~ NAME_REGEX && cli.global.events.map(&:action).none?(input) }
        q.modify :trim
        q.messages[:valid?] = format_warning("Invalid event name. Only lowercase/numbers/underscores allowed. " \
                                             "Ensure %{value} is not an existing event.")
        q.messages[:required?] = Text::EVENT_ACTION_HELP
      end
    end

    def prompt_for_context
      new_page!(3, 7, STEPS)
      cli.say format_prompt("EVENT CONTEXT #{counter(0, 2)}")
      prompt_for_identifiers

      new_page!(3, 7, STEPS) # Same "step" but increment counter
      cli.say format_prompt("EVENT CONTEXT #{counter(1, 2)}")
      prompt_for_additional_properties
    end

    def prompt_for_identifiers
      cli.say Text::EVENT_IDENTIFIERS_INTRO % event.action

      identifiers = prompt_for_array_selection(
        'Which identifiers are available when the event occurs?',
        IDENTIFIER_OPTIONS.keys,
        per_page: IDENTIFIER_OPTIONS.length
      ) { |choice| format_identifier_choice(choice) }

      event.identifiers = identifiers if identifiers.any?
    end

    def format_identifier_choice(choice)
      formatted_choice = choice.empty? ? 'None' : "[#{choice.sort.join(', ')}]"
      buffer = IDENTIFIER_FORMATTING_BUFFER - formatted_choice.length

      "#{formatted_choice}#{' ' * buffer} -- #{IDENTIFIER_OPTIONS[choice]}"
    end

    def prompt_for_additional_properties
      cli.say Text::ADDITIONAL_PROPERTIES_INTRO

      available_props = [:label, :property, :value]

      while available_props.any?
        disabled = format_help('(already defined)')

        # rubocop:disable Rails/NegateInclude -- this isn't Rails
        options = [
          { value: :none, name: 'None! Continue to next section!' },
          disableable_option(
            value: :label,
            name: 'String 1 (attribute will be named `label`)',
            disabled: disabled
          ) { !available_props.include?(:label) },
          disableable_option(
            value: :property,
            name: 'String 2 (attribute will be named `property`)',
            disabled: disabled
          ) { !available_props.include?(:property) },
          disableable_option(
            value: :value,
            name: 'Number (attribute will be named `value`)',
            disabled: disabled
          ) { !available_props.include?(:value) }
        ]
        # rubocop:enable Rails/NegateInclude

        selected_property = cli.select(
          "Which additional property do you want to add to the event?",
          options,
          help: format_help("(will reprompt for multiple)"),
          **select_opts,
          &disabled_format_callback
        )

        if selected_property == :none
          available_props.clear
        else
          available_props.delete(selected_property)
          property_description = prompt_for_text('Describe what the field will include:')

          event.additional_properties ||= {}
          event.additional_properties[selected_property.to_s] = {
            'description' => property_description || 'TODO'
          }
        end
      end
    end

    def prompt_for_url
      new_page!(4, 7, STEPS)

      event.introduced_by_url = prompt_for_text('Which MR URL will merge the event definition?')
    end

    def prompt_for_product_group
      new_page!(5, 7, STEPS)

      product_group = prompt_for_group_ownership('Which group will own the event?')

      event.product_group = product_group
    end

    def prompt_for_tier
      new_page!(6, 7, STEPS)

      event.tiers = prompt_for_array_selection(
        'Which tiers will the event be recorded on?',
        [%w[free premium ultimate], %w[premium ultimate], %w[ultimate]]
      )

      event.distributions = event.tiers.include?('free') ? %w[ce ee] : %w[ee]
    end

    def create_event_file
      new_page!(7, 7, STEPS)

      prompt_to_save_file(event.file_path, event.formatted_output)
    end

    def display_result(outcome)
      new_page!

      cli.say <<~TEXT
        #{divider}
        #{format_info('Done with event definition!')}

        #{outcome || '  No files saved.'}

        #{divider}

          Do you need to create a metric? Probably!

          Metrics are required to pull any usage data from self-managed instances or GitLab-Dedicated through Service Ping. Collected metric data can viewed in Tableau. Individual event details from GitLab.com can also be accessed through Snowflake.

          Typical flow: Define event > Define metric > Instrument app code > Merge/Deploy MR > Verify data in Tableau/Snowflake

      TEXT
    end

    def prompt_for_next_steps
      next_step = cli.select("How would you like to proceed?", **select_opts) do |menu|
        menu.enum "."

        menu.choice "New Event -- define another event", :new_event

        choice = if File.exist?(event.file_path)
                   ["Create Metric -- define a new metric using #{event.action}.yml", :add_metric]
                 else
                   ["Save & Create Metric -- save #{event.action}.yml and define a matching metric", :save_and_add]
                 end

        menu.default choice[0]
        menu.choice(*choice)

        menu.choice "View Usage -- look at code examples for #{event.action}.yml", :view_usage
        menu.choice 'Exit', :exit
      end

      case next_step
      when :new_event
        InternalEventsCli::EventDefiner.new(cli).run
      when :add_metric
        MetricDefiner.new(cli, event.file_path).run
      when :save_and_add
        write_to_file(event.file_path, event.formatted_output, 'create')

        MetricDefiner.new(cli, event.file_path).run
      when :view_usage
        UsageViewer.new(cli, event.file_path, event).run
      when :exit
        cli.say Text::FEEDBACK_NOTICE
      end
    end
  end
end
