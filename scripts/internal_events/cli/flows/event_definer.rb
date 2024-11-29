# frozen_string_literal: true

require_relative '../helpers'
require_relative '../text/event_definer'

# Entrypoint for flow to create an event definition file
module InternalEventsCli
  module Flows
    class EventDefiner
      include Helpers
      include Text::EventDefiner

      SCHEMA = ::JSONSchemer.schema(Pathname('config/events/schema.json'))
      STEPS = [
        'New Event',
        'Description',
        'Name',
        'Context',
        'URL',
        'Group',
        'Categories',
        'Tiers',
        'Save files'
      ].freeze

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
        prompt_for_product_categories
        prompt_for_tier

        outcome = create_event_file
        display_result(outcome)

        prompt_for_next_steps
      end

      private

      def prompt_for_description
        new_page!(on_step: 'Description', steps: STEPS)
        cli.say DESCRIPTION_INTRO

        event.description = cli.ask("Describe what the event tracks: #{input_required_text}", **input_opts) do |q|
          q.required true
          q.modify :trim
          q.messages[:required?] = DESCRIPTION_HELP
        end
      end

      def prompt_for_action
        new_page!(on_step: 'Name', steps: STEPS)
        cli.say ACTION_INTRO

        event.action = cli.ask("Define the event name: #{input_required_text}", **input_opts) do |q|
          q.required true
          q.validate ->(input) { input =~ NAME_REGEX && cli.global.events.map(&:action).none?(input) }
          q.modify :trim
          q.messages[:valid?] = format_warning(
            "Invalid event name. Only lowercase/numbers/underscores allowed. " \
              "Ensure %{value} is not an existing event.")
          q.messages[:required?] = ACTION_HELP
        end
      end

      def prompt_for_context
        new_page!(on_step: 'Context', steps: STEPS)
        cli.say format_prompt("EVENT CONTEXT #{counter(0, 2)}")
        prompt_for_identifiers

        new_page!(on_step: 'Context', steps: STEPS) # Same "step" but increment counter
        cli.say format_prompt("EVENT CONTEXT #{counter(1, 2)}")
        prompt_for_additional_properties
      end

      def prompt_for_identifiers
        cli.say IDENTIFIERS_INTRO % event.action

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
        cli.say ADDITIONAL_PROPERTIES_INTRO

        available_props = [:label, :property, :value, :add_extra_prop]

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
            ) { !available_props.include?(:value) },
            disableable_option(
              value: :add_extra_prop,
              name: 'Add extra property (attribute will be named the input custom name)',
              disabled: format_warning('(option disabled - use label/property/value first)')
            ) do
              !((!available_props.include?(:label) &&
                  !available_props.include?(:property)) ||
                  !available_props.include?(:value))
            end
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
          elsif selected_property == :add_extra_prop
            property_name = prompt_for_add_extra_properties
            property_description = prompt_for_text('Describe what the field will include:')
            assign_extra_properties(property_name, property_description)
          else
            available_props.delete(selected_property)
            property_description = prompt_for_text('Describe what the field will include:')
            assign_extra_properties(selected_property, property_description)
          end
        end
      end

      def assign_extra_properties(property, description = nil)
        event.additional_properties ||= {}
        event.additional_properties[property.to_s] = {
          'description' => description || 'TODO'
        }
      end

      def prompt_for_add_extra_properties
        primary_props = %w[label property value]

        prompt_for_text('Define a name for the attribute:', **input_opts) do |q|
          q.required true
          q.validate ->(input) { input =~ NAME_REGEX && primary_props.none?(input) }
          q.modify :trim
          q.messages[:required?] = ADDITIONAL_PROPERTIES_ADD_MORE_HELP
          q.messages[:valid?] = format_warning(
            "Invalid property name. Only lowercase/numbers/underscores allowed. " \
              "Ensure %{value} is not one of `property, label, value`.")
        end
      end

      def prompt_for_url
        new_page!(on_step: 'URL', steps: STEPS)

        event.introduced_by_url = prompt_for_text('Which MR URL will merge the event definition?')
      end

      def prompt_for_product_group
        new_page!(on_step: 'Group', steps: STEPS)

        product_group = prompt_for_group_ownership('Which group will own the event?')

        event.product_group = product_group
      end

      def prompt_for_product_categories
        new_page!(on_step: 'Categories', steps: STEPS)
        cli.say <<~TEXT
          #{format_info('FEATURE CATEGORY')}
          Refer to https://handbook.gitlab.com/handbook/product/categories for information on current product categories.

        TEXT

        event.product_categories = prompt_for_feature_categories(
          'Which feature categories best fit this event?',
          [event.product_group]
        )
      end

      def prompt_for_tier
        new_page!(on_step: 'Tiers', steps: STEPS)

        event.tiers = prompt_for_array_selection(
          'Which tiers will the event be recorded on?',
          [%w[free premium ultimate], %w[premium ultimate], %w[ultimate]]
        )
      end

      def create_event_file
        new_page!(on_step: 'Save files', steps: STEPS)

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
          EventDefiner.new(cli).run
        when :add_metric
          MetricDefiner.new(cli, event.file_path).run
        when :save_and_add
          write_to_file(event.file_path, event.formatted_output, 'create')

          MetricDefiner.new(cli, event.file_path).run
        when :view_usage
          UsageViewer.new(cli, event.file_path, event).run
        when :exit
          cli.say feedback_notice
        end
      end
    end
  end
end
