# frozen_string_literal: true

require_relative './helpers'

module InternalEventsCli
  class MetricDefiner
    include Helpers

    SCHEMA = ::JSONSchemer.schema(Pathname('config/metrics/schema/base.json'))
    STEPS = [
      'New Metric',
      'Type',
      'Events',
      'Scope',
      'Descriptions',
      'Copy event',
      'Group',
      'URL',
      'Tiers',
      'Save files'
    ].freeze

    attr_reader :cli

    def initialize(cli, starting_event = nil)
      @cli = cli
      @selected_event_paths = Array(starting_event)
      @metrics = []
    end

    def run
      type = prompt_for_metric_type
      prompt_for_events(type)

      return unless @selected_event_paths.any?

      prompt_for_metrics

      return unless @metrics.any?

      prompt_for_description
      defaults = prompt_for_copying_event_properties
      prompt_for_product_ownership(defaults)
      prompt_for_url(defaults)
      prompt_for_tier(defaults)
      outcomes = create_metric_files
      prompt_for_next_steps(outcomes)
    end

    private

    def events
      @events ||= events_by_filepath(@selected_event_paths)
    end

    def selected_events
      @selected_events ||= events.values_at(*@selected_event_paths)
    end

    def prompt_for_metric_type
      return if @selected_event_paths.any?

      new_page!(1, 9, STEPS)

      cli.select("Which best describes what the metric should track?", **select_opts) do |menu|
        menu.enum "."

        menu.choice 'Single event    -- count occurrences of a specific event or user interaction', :event_metric
        menu.choice 'Multiple events -- count occurrences of several separate events or interactions', :aggregate_metric
        menu.choice 'Database        -- record value of a particular field or count of database rows', :database_metric
      end
    end

    def prompt_for_events(type)
      return if @selected_event_paths.any?

      new_page!(2, 9, STEPS)

      case type
      when :event_metric
        cli.say "For robust event search, use the Metrics Dictionary: https://metrics.gitlab.com/snowplow\n\n"

        @selected_event_paths = [cli.select(
          'Which event does this metric track?',
          get_event_options(events),
          **select_opts,
          **filter_opts(header_size: 7)
        )]
      when :aggregate_metric
        cli.say "For robust event search, use the Metrics Dictionary: https://metrics.gitlab.com/snowplow\n\n"

        @selected_event_paths = cli.multi_select(
          'Which events does this metric track? (Space to select)',
          get_event_options(events),
          **multiselect_opts,
          **filter_opts(header_size: 7)
        )
      when :database_metric
        cli.error Text::DATABASE_METRIC_NOTICE
        cli.say Text::FEEDBACK_NOTICE
      end
    end

    def prompt_for_metrics
      eligible_metrics = get_metric_options(selected_events)

      if eligible_metrics.all? { |metric| metric[:disabled] }
        cli.error Text::ALL_METRICS_EXIST_NOTICE
        cli.say Text::FEEDBACK_NOTICE

        return
      end

      new_page!(3, 9, STEPS)

      @metrics = cli.select('Which metrics do you want to add?', eligible_metrics, **select_opts)

      assign_shared_attrs(:actions, :milestone) do
        {
          actions: selected_events.map(&:action).sort,
          milestone: MILESTONE
        }
      end
    end

    def prompt_for_description
      new_page!(4, 9, STEPS)

      cli.say Text::METRIC_DESCRIPTION_INTRO
      cli.say selected_event_descriptions.join('')

      base_description = nil

      @metrics.each_with_index do |metric, idx|
        multiline_prompt = [
          counter(idx, @metrics.length),
          format_prompt("Complete the text:"),
          "How would you describe this metric to a non-technical person?",
          input_required_text,
          "\n\n   Technical description:  #{metric.technical_description}"
        ].compact.join(' ')

        last_line_of_prompt = "\n  Finish the description:  #{format_info("#{metric.prefix}...")}"

        cli.say("\n")
        cli.say(multiline_prompt)

        description_help_message = [
          Text::METRIC_DESCRIPTION_HELP,
          multiline_prompt,
          "\n\n"
        ].join("\n")

        # Reassign base_description so the next metric's default value is their own input
        base_description = cli.ask(last_line_of_prompt, value: base_description.to_s) do |q|
          q.required true
          q.modify :trim
          q.messages[:required?] = description_help_message
        end

        cli.say("\n") # looks like multiline input, but isn't. Spacer improves clarity.

        metric.description = "#{metric.prefix} #{base_description}"
      end
    end

    def selected_event_descriptions
      @selected_event_descriptions ||= selected_events.map do |event|
        "  #{event.action} - #{format_selection(event.description)}\n"
      end
    end

    # Check existing event files for attributes to copy over
    def prompt_for_copying_event_properties
      defaults = collect_values_for_shared_event_properties

      return {} if defaults.none?

      new_page!(5, 9, STEPS)

      cli.say <<~TEXT
        #{format_info('Convenient! We can copy these attributes from the event definition(s):')}

        #{defaults.compact.transform_keys(&:to_s).to_yaml(line_width: 150)}
        #{format_info('If any of these attributes are incorrect, you can also change them manually from your text editor later.')}

      TEXT

      cli.select('What would you like to do?', **select_opts) do |menu|
        menu.enum '.'
        menu.choice 'Copy & continue', -> { bulk_assign(defaults) }
        menu.choice 'Modify attributes'
      end

      defaults
    end

    def collect_values_for_shared_event_properties
      fields = Hash.new { |h, k| h[k] = [] }

      selected_events.each do |event|
        fields[:introduced_by_url] << event.introduced_by_url
        fields[:product_section] << event.product_section
        fields[:product_stage] << event.product_stage
        fields[:product_group] << event.product_group
        fields[:distribution] << event.distributions&.sort
        fields[:tier] << event.tiers&.sort
      end

      # Keep event values if every selected event is the same
      fields.each_with_object({}) do |(attr, values), defaults|
        next unless values.compact.uniq.length == 1

        defaults[attr] ||= values.first
      end
    end

    def prompt_for_product_ownership(defaults)
      assign_shared_attrs(:product_section, :product_stage, :product_group) do
        new_page!(6, 9, STEPS)

        prompt_for_group_ownership(
          {
            product_section: 'Which section owns the metric?',
            product_stage: 'Which stage owns the metric?',
            product_group: 'Which group owns the metric?'
          },
          defaults.slice(:product_section, :product_stage, :product_group)
        )
      end
    end

    def prompt_for_url(defaults)
      assign_shared_attr(:introduced_by_url) do
        new_page!(7, 9, STEPS)

        prompt_for_text(
          "Which MR URL introduced the metric?",
          defaults[:introduced_by_url]
        )
      end
    end

    def prompt_for_tier(defaults)
      assign_shared_attr(:tier) do
        new_page!(8, 9, STEPS)

        prompt_for_array_selection(
          'Which tiers will the metric be reported from?',
          [%w[free premium ultimate], %w[premium ultimate], %w[ultimate]],
          defaults[:tier]
        )
      end

      assign_shared_attr(:distribution) do |metric|
        metric.tier.include?('free') ? %w[ce ee] : %w[ee]
      end
    end

    def create_metric_files
      @metrics.map.with_index do |metric, idx|
        new_page!(9, 9, STEPS) # Repeat the same step number but increment metric counter

        cli.say format_prompt("SAVING FILE #{counter(idx, @metrics.length)}: #{metric.technical_description}\n")

        prompt_to_save_file(metric.file_path, metric.formatted_output)
      end
    end

    def prompt_for_next_steps(outcomes = [])
      new_page!

      outcome = outcomes.any? ? outcomes.compact.join("\n") : '  No files saved.'

      cli.say <<~TEXT
        #{divider}
        #{format_info('Done with metric definitions!')}

        #{outcome}

        #{divider}
      TEXT

      cli.select("How would you like to proceed?", **select_opts) do |menu|
        menu.enum "."
        menu.choice "View Usage -- look at code examples for #{@selected_event_paths.first}", -> do
          UsageViewer.new(cli, @selected_event_paths.first, selected_events.first).run
        end
        menu.choice 'Exit', -> { cli.say Text::FEEDBACK_NOTICE }
      end
    end

    def assign_shared_attrs(...)
      metric = @metrics.first
      attrs = metric.to_h.slice(...)
      attrs = yield(metric) unless attrs.values.all?

      bulk_assign(attrs)
    end

    def assign_shared_attr(key)
      assign_shared_attrs(key) do |metric|
        { key => yield(metric) }
      end
    end

    def bulk_assign(attrs)
      @metrics.each { |metric| metric.bulk_assign(attrs) }
    end
  end
end
