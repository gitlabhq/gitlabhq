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
      %w[] => "Use case: For instance-level events without user interaction [LEAST COMMON]"
    }.freeze

    IDENTIFIER_FORMATTING_BUFFER = "[#{IDENTIFIER_OPTIONS.keys.max_by(&:length).join(', ')}]".length

    attr_reader :cli, :event

    def initialize(cli)
      @cli = cli
      @event = Event.new(milestone: MILESTONE)
    end

    def run
      prompt_for_description
      prompt_for_action
      prompt_for_identifiers
      prompt_for_url
      prompt_for_product_ownership
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
        q.validate ->(input) { input =~ /\A[a-z1-9_]+\z/ && !events_by_filepath.values.map(&:action).include?(input) } # rubocop:disable Rails/NegateInclude -- Not rails
        q.modify :trim
        q.messages[:valid?] = format_warning("Invalid event name. Only lowercase/numbers/underscores allowed. " \
                                             "Ensure %{value} is not an existing event.")
        q.messages[:required?] = Text::EVENT_ACTION_HELP
      end
    end

    def prompt_for_identifiers
      new_page!(3, 7, STEPS)
      cli.say Text::EVENT_IDENTIFIERS_INTRO % event.action

      identifiers = prompt_for_array_selection(
        'Which identifiers are available when the event occurs?',
        IDENTIFIER_OPTIONS.keys
      ) { |choice| format_identifier_choice(choice) }

      event.identifiers = identifiers if identifiers.any?
    end

    def format_identifier_choice(choice)
      formatted_choice = choice.empty? ? 'None' : "[#{choice.sort.join(', ')}]"
      buffer = IDENTIFIER_FORMATTING_BUFFER - formatted_choice.length

      "#{formatted_choice}#{' ' * buffer} -- #{IDENTIFIER_OPTIONS[choice]}"
    end

    def prompt_for_url
      new_page!(4, 7, STEPS)

      event.introduced_by_url = prompt_for_text('Which MR URL will merge the event definition?')
    end

    def prompt_for_product_ownership
      new_page!(5, 7, STEPS)

      ownership = prompt_for_group_ownership({
        product_section: 'Which section will own the event?',
        product_stage: 'Which stage will own the event?',
        product_group: 'Which group will own the event?'
      })

      event.bulk_assign(ownership)
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

          Want to have data reported in Snowflake/Tableau/ServicePing? Add a new metric for your event!

      TEXT
    end

    def prompt_for_next_steps
      next_step = cli.select("How would you like to proceed?", **select_opts) do |menu|
        menu.enum "."

        if File.exist?(event.file_path)
          menu.choice "Create Metric -- define a new metric using #{event.action}.yml", :add_metric
        else
          menu.choice "Save & Create Metric -- save #{event.action}.yml and define a matching metric", :save_and_add
        end

        menu.choice "View Usage -- look at code examples for #{event.action}.yml", :view_usage
        menu.choice 'Exit', :exit
      end

      case next_step
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
