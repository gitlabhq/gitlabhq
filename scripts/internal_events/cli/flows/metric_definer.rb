# frozen_string_literal: true

require_relative '../helpers'
require_relative '../text/metric_definer'

# Entrypoint for flow to create an metric definition file
module InternalEventsCli
  module Flows
    class MetricDefiner
      include Helpers
      include Text::MetricDefiner

      SCHEMA = ::JSONSchemer.schema(Pathname('config/metrics/schema/base.json'))
      STEPS = [
        'New Metric',
        'Type',
        'Events',
        'Scope',
        'Descriptions',
        'Copy event',
        'Group',
        'Categories',
        'URL',
        'Tiers',
        'Save files'
      ].freeze

      attr_reader :cli

      def initialize(cli, starting_event = nil)
        @cli = cli
        @selected_event_paths = Array(starting_event)
        @metrics = []
        @selected_filters = {}
      end

      def run
        type = prompt_for_metric_type
        prompt_for_events(type)

        return unless @selected_event_paths.any?

        prompt_for_metrics
        prompt_for_event_filters

        return unless @metrics.any?

        prompt_for_descriptions
        defaults = prompt_for_copying_event_properties
        prompt_for_product_group(defaults)
        prompt_for_product_categories(defaults)
        prompt_for_url(defaults)
        prompt_for_tier(defaults)
        outcomes = create_metric_files
        prompt_for_next_steps(outcomes)
      end

      private

      # ----- Memoization Helpers -----------------

      def events
        @events ||= events_by_filepath(@selected_event_paths)
      end

      def selected_events
        @selected_events ||= events.values_at(*@selected_event_paths)
      end

      # ----- Prompts -----------------------------

      def prompt_for_metric_type
        return if @selected_event_paths.any?

        new_page!(on_step: 'Type', steps: STEPS)

        cli.select("Which best describes what the metric should track?", **select_opts) do |menu|
          menu.enum "."

          menu.choice 'Single event    -- count occurrences of a specific event or user interaction',
            :event_metric
          menu.choice 'Multiple events -- count occurrences of several separate events or interactions',
            :aggregate_metric
          menu.choice 'Database        -- record value of a particular field or count of database rows',
            :database_metric
        end
      end

      def prompt_for_events(type)
        return if @selected_event_paths.any?

        new_page!(on_step: 'Events', steps: STEPS)

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
          cli.error DATABASE_METRIC_NOTICE
          cli.say feedback_notice
        end
      end

      def prompt_for_metrics
        eligible_metrics = get_metric_options(selected_events)

        if eligible_metrics.all? { |metric| metric[:disabled] }
          cli.error ALL_METRICS_EXIST_NOTICE
          cli.say feedback_notice

          return
        end

        new_page!(on_step: 'Scope', steps: STEPS)
        cli.say format_info('SELECTED EVENTS')
        cli.say selected_events_filter_options.join
        cli.say "\n"

        @metrics = cli.select(
          'Which metrics do you want to add?',
          eligible_metrics,
          **select_opts,
          **filter_opts,
          per_page: 20,
          &disabled_format_callback
        )
        @metrics = reduce_metrics_by_time_frame(@metrics)

        assign_shared_attrs(:actions, :milestone) do
          {
            actions: selected_events.map(&:action).sort,
            milestone: MILESTONE
          }
        end
      end

      def prompt_for_event_filters
        return if @metrics.none?(&:filters_expected?)

        selected_unique_identifier = @metrics.first.identifier.value
        event_count = selected_events.length
        previous_inputs = {
          'label' => nil,
          'property' => nil,
          'value' => nil
        }

        event_filters = selected_events.dup.flat_map.with_index do |event, idx|
          print_event_filter_header(event, idx, event_count)

          next if deselect_nonfilterable_event?(event) # prompts user

          filter_values = event.additional_properties&.filter_map do |property, _|
            next if selected_unique_identifier == property

            prompt_for_property_filter(
              event.action,
              property,
              previous_inputs[property]
            )
          end

          previous_inputs.merge!(@selected_filters[event.action] || {})

          find_filter_permutations(event.action, filter_values)
        end.compact

        bulk_assign(filters: event_filters)
      end

      def prompt_for_descriptions
        default_description = nil
        default_key = nil

        separate_page_per_metric = @metrics.any? do |metric|
          name_requirement_reason(metric)
        end

        @metrics.each_with_index do |metric, idx|
          if idx == 0 || separate_page_per_metric
            new_page!(on_step: 'Descriptions', steps: STEPS)

            cli.say DESCRIPTION_INTRO
            cli.say selected_event_descriptions.join
          end

          cli.say "\n"
          cli.say format_prompt(format_subheader(
            'DESCRIBING METRIC',
            metric.technical_description,
            idx,
            @metrics.length
          ))

          prompt_for_description(metric, default_description).tap do |description|
            default_description = description
            metric.description = "#{metric.description_prefix} #{description}"
          end

          prompt_for_metric_name(metric, default_key)&.tap do |key|
            default_key = key
            metric.key = key
          end
        end
      end

      def file_saved_context_message(attributes)
        format_prefix "  ", <<~TEXT.chomp
          - Visit #{format_info('https://metrics.gitlab.com')} to find dashboard links for this metric
          #{metric_dashboard_links(attributes)}
        TEXT
      end

      def metric_dashboard_links(attributes)
        time_frames = attributes['time_frame']
        unless time_frames.is_a?(Array)
          return "- Metric trend dashboard: #{format_info(metric_trend_path(attributes['key_path']))}"
        end

        dashboards = time_frames.map do |time_frame|
          key_path = TimeFramedKeyPath.build(attributes['key_path'], time_frame)
          "  - #{format_info(metric_trend_path(key_path))}"
        end
        ["- Metric trend dashboards:", *dashboards].join("\n")
      end

      # Check existing event files for attributes to copy over
      def prompt_for_copying_event_properties
        shared_values = collect_values_for_shared_event_properties
        defaults = shared_values.except(:stage, :section)

        return {} if shared_values.none?

        return shared_values if defaults.none?

        new_page!(on_step: 'Copy event', steps: STEPS)

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

        shared_values
      end

      def prompt_for_product_group(defaults)
        assign_shared_attr(:product_group) do
          new_page!(on_step: 'Group', steps: STEPS)

          prompt_for_group_ownership('Which group owns the metric?', defaults)
        end
      end

      def prompt_for_product_categories(defaults)
        assign_shared_attr(:product_categories) do
          new_page!(on_step: 'Categories', steps: STEPS)
          cli.say <<~TEXT
            #{format_info('FEATURE CATEGORY')}
            Refer to https://handbook.gitlab.com/handbook/product/categories for information on current product categories.

          TEXT

          potential_groups = [
            *@metrics.map(&:product_group),
            *selected_events.map(&:product_group),
            defaults[:product_group]
          ]
          prompt_for_feature_categories(
            'Which feature categories best fit this metric?',
            potential_groups,
            defaults[:product_categories]
          )
        end
      end

      def prompt_for_url(defaults)
        assign_shared_attr(:introduced_by_url) do
          new_page!(on_step: 'URL', steps: STEPS)

          prompt_for_text(
            'Which MR URL introduced the metric?',
            defaults[:introduced_by_url]
          )
        end
      end

      def prompt_for_tier(defaults)
        assign_shared_attr(:tiers) do
          new_page!(on_step: 'Tiers', steps: STEPS)

          prompt_for_array_selection(
            'Which tiers will the metric be reported from?',
            [%w[free premium ultimate], %w[premium ultimate], %w[ultimate]],
            defaults[:tiers]
          )
        end
      end

      def create_metric_files
        @metrics.map.with_index do |metric, idx|
          new_page!(on_step: 'Save files', steps: STEPS) # Repeat the same step but increment metric counter

          cli.say format_prompt(format_subheader('SAVING FILE', metric.description, idx, @metrics.length))
          cli.say "\n"

          prompt_to_save_file(metric.file_path, metric.formatted_output)
        end
      end

      def prompt_for_next_steps(outcomes = [])
        new_page!

        outcome = outcomes.any? ? outcomes.compact.join("\n") : '  No files saved.'
        metric = @metrics.first

        cli.say <<~TEXT
          #{divider}
          #{format_info('Done with metric definitions!')}

          #{outcome}
          #{divider}

            Have you instrumented the application code to trigger the event yet? View usage examples to easily copy/paste implementation!

            Want to verify the metrics? Check out the group::#{metric[:product_group]} Metrics Exploration Dashboard in Tableau
              Note: The Metrics Exploration Dashboard data would be available ~1 week after deploy for Gitlab.com, ~1 week after next release for self-managed
              Link: #{format_info(metric_exploration_group_path(metric[:product_group], find_stage(metric.product_group)))}

            Typical flow: Define event > Define metric > Instrument app code > Merge/Deploy MR > Verify data in Tableau/Snowflake

        TEXT

        actions = selected_events.map(&:action).join(', ')
        next_step = cli.select("How would you like to proceed?", **select_opts) do |menu|
          menu.enum "."

          menu.choice "New Event -- define a new event", :new_event
          menu.choice "New Metric -- define another metric for #{actions}", :new_metric_with_events
          menu.choice "New Metric -- define another metric", :new_metric
          choice = "View Usage -- look at code examples for event #{selected_events.first.action}"
          menu.default choice
          menu.choice choice, :view_usage
          menu.choice 'Exit', :exit
        end

        case next_step
        when :new_event
          EventDefiner.new(cli).run
        when :new_metric_with_events
          MetricDefiner.new(cli, @selected_event_paths).run
        when :new_metric
          MetricDefiner.new(cli).run
        when :view_usage
          UsageViewer.new(cli, @selected_event_paths.first, selected_events.first).run
        when :exit
          cli.say feedback_notice
        end
      end

      # ----- Prompt-specific Helpers -------------

      # Helper for #prompt_for_metrics
      def selected_events_filter_options
        filterable_events_selected = selected_events.any? { |event| event.additional_properties&.any? }

        selected_events.map do |event|
          filters = event.additional_properties&.keys
          filter_phrase = if filters
                            " (filterable by #{filters&.join(', ')})"
                          elsif filterable_events_selected
                            ' -- not filterable'
                          end

          "  - #{event.action}#{format_help(filter_phrase)}\n"
        end
      end

      def reduce_metrics_by_time_frame(metrics)
        # MetricOptions class returns one metric per time_frame value,
        # here we merge them into a singular metric including all the time_frame values
        return metrics unless metrics.length > 1

        time_frames = metrics.map do |metric|
          metric.time_frame.value
        end

        attributes = metrics.first.to_h.merge(time_frame: time_frames)
        [Metric.new(**attributes)]
      end

      # Helper for #prompt_for_event_filters
      def print_event_filter_header(event, idx, total)
        cli.say "\n"
        cli.say format_info(format_subheader('SETTING EVENT FILTERS', event.action, idx, total))

        return unless event.additional_properties&.any?

        event_filter_options = event.additional_properties.map do |property, attrs|
          "  #{property}: #{attrs['description']}\n"
        end

        cli.say event_filter_options.join
      end

      # Helper for #prompt_for_event_filters
      def deselect_nonfilterable_event?(event)
        cli.say "\n"

        return false if event.additional_properties&.any?
        return false if cli.yes?("This event is not filterable. Should it be included in the metric?", **yes_no_opts)

        selected_events.delete(event)
        bulk_assign(actions: selected_events.map(&:action).sort)

        true
      end

      # Helper for #prompt_for_event_filters
      def prompt_for_property_filter(action, property, default)
        formatted_prop = format_info(property)
        prompt = "Count where #{formatted_prop} equals any of (comma-sep):"

        inputs = prompt_for_text(prompt, default, **input_opts) do |q|
          if property == 'value'
            q.convert ->(input) { input.split(',').map(&:to_i).uniq }
            q.validate %r{^(\d|\s|,)*$}
            q.messages[:valid?] = "Inputs for #{formatted_prop} must be numeric"
          elsif property == 'property' || property == 'label'
            q.convert ->(input) { input.split(',').map(&:strip).uniq }
          else
            q.convert ->(input) do
              input.split(',').map do |value|
                val = value.strip
                cast_if_numeric(val)
              end.uniq
            end
          end
        end

        return unless inputs&.any?

        @selected_filters[action] ||= {}
        @selected_filters[action][property] = inputs.join(',')

        inputs.map { |input| { property => input } }.uniq
      end

      def cast_if_numeric(text)
        float = Float(text)
        float % 1 == 0 ? float.to_i : float
      rescue ArgumentError
        text
      end

      # Helper for #prompt_for_event_filters
      #
      # Gets all the permutations of the provided property values.
      # @param filters [Array] ex) [{ 'label' => 'red' }, { 'label' => 'blue' }, { value => 16 }]
      # @return ex) [{ 'label' => 'red', value => 16 }, { 'label' => 'blue', value => 16 }]
      def find_filter_permutations(action, filters)
        # Define a filter for all events, regardless of the available props so NewMetric#events is correct
        return [[action, {}]] unless filters&.any?

        # Uses proc syntax to avoid spliting & type-checking `filters`
        :product.to_proc.call(*filters).map do |filter|
          [action, filter.reduce(&:merge)]
        end
      end

      # Helper for #prompt_for_descriptions
      def selected_event_descriptions
        selected_events.map do |event|
          filters = @selected_filters[event.action]

          if filters&.any?
            filter_phrase = filters.map { |k, v| "#{k}=#{v}" }.join(' ')
            filter_phrase = format_help("(#{filter_phrase})")
          end

          "  #{event.action}#{filter_phrase} - #{format_selection(event.description)}\n"
        end
      end

      # Helper for #prompt_for_descriptions
      def prompt_for_description(metric, default)
        description_start = format_info("#{metric.description_prefix}...")

        cli.say <<~TEXT

          #{input_opts[:prefix]} How would you describe this metric to a non-technical person? #{input_required_text}

        TEXT

        prompt_for_text("  Finish the description: #{description_start}", default, multiline: true) do |q|
          q.required true
          q.modify :trim
          q.messages[:required?] = DESCRIPTION_HELP
        end
      end

      # Helper for #prompt_for_descriptions
      def prompt_for_metric_name(metric, default)
        name_reason = name_requirement_reason(metric)
        default_name = metric.key.value
        display_name = metric.key.value("\e[0m[REPLACE ME]\e[36m")
        empty_name = metric.key.value('')

        return unless name_reason

        cli.say <<~TEXT

          #{input_opts[:prefix]} #{name_reason[:text]} How should we refererence this metric? #{input_required_text}

                      ID:  #{format_info(display_name)}
                Filename:  #{format_info(display_name)}#{format_info('.yml')}

        TEXT

        max_length = MAX_FILENAME_LENGTH - "#{empty_name}.yml".length
        help_tokens = { name: default_name, count: max_length }

        prompt_for_text('  Replace with: ', default, multiline: true) do |q|
          q.required true
          q.messages[:required?] = name_reason[:help] % help_tokens
          q.messages[:valid?] = NAME_ERROR % help_tokens
          q.validate ->(input) do
            input.length <= max_length &&
              input.match?(NAME_REGEX) &&
              !conflicting_key_path?(metric.key.value(input))
          end
        end
      end

      # Helper for #prompt_for_descriptions
      def name_requirement_reason(metric)
        if metric.filters.assigned?
          NAME_REQUIREMENT_REASONS[:filters]
        elsif metric.file_name.length > MAX_FILENAME_LENGTH
          NAME_REQUIREMENT_REASONS[:length]
        elsif conflicting_key_path?(metric.key_path)
          NAME_REQUIREMENT_REASONS[:conflict]
        end
      end

      # Helper for #prompt_for_descriptions
      def conflicting_key_path?(key_path)
        cli.global.metrics.any? do |existing_metric|
          existing_metric.key_path == key_path
        end
      end

      # Helper for #prompt_for_copying_event_properties
      def collect_values_for_shared_event_properties
        fields = Hash.new { |h, k| h[k] = [] }

        selected_events.each do |event|
          fields[:introduced_by_url] << event.introduced_by_url
          fields[:product_group] << event.product_group
          fields[:stage] << find_stage(event.product_group)
          fields[:section] << find_section(event.product_group)
          fields[:product_categories] << event.product_categories
          fields[:tiers] << event.tiers&.sort
        end

        defaults = {}

        # Use event value as default if it's the same for all
        # selected events because it's unlikely to be different
        fields.each do |field, values|
          next unless values.compact.uniq.length == 1

          defaults[field] ||= values.first
        end

        # If an event is relevant to a category, then the metric
        # will be too, so we'll collect all categories
        defaults[:product_categories] = KNOWN_CATEGORIES & fields[:product_categories].flatten
        defaults.delete(:product_categories) if defaults[:product_categories].empty?

        defaults
      end

      # ----- Shared Helpers ----------------------

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
end
