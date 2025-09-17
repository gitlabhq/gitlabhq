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
        'Config',
        'Scope',
        'Description',
        'Defaults',
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
        @metric = nil
        @selected_filters = {}
      end

      def run
        type = prompt_for_metric_type

        prompt_for_configuration(type)

        return unless metric

        metric.milestone = MILESTONE
        prompt_for_description
        prompt_for_metric_name
        defaults = prompt_for_copying_event_properties
        prompt_for_product_group(defaults)
        prompt_for_product_categories(defaults)
        prompt_for_url(defaults)
        prompt_for_tier(defaults)
        outcome = create_metric_file
        prompt_for_next_steps(outcome)
      end

      private

      attr_reader :metric

      # ----- Memoization Helpers -----------------

      def events
        @events ||= events_by_filepath(@selected_event_paths)
      end

      def selected_events
        @selected_events ||= events.values_at(*@selected_event_paths)
      end

      # ----- Prompts -----------------------------

      def prompt_for_metric_type
        return :event_metric if @selected_event_paths.any?

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

      def prompt_for_configuration(type)
        case type
        # TODO: replace code blocks with event & db subflow classes https://gitlab.com/gitlab-org/gitlab/-/issues/464066
        when :database_metric
          # CLI doesn't load rails, so perform a simplified string <-> boolean check
          if [nil, 'false', '0'].include? ENV['ENABLE_DATABASE_METRIC']
            cli.error DATABASE_METRIC_NOTICE
            cli.say feedback_notice
            return
          end

          @metric = Metric.new
          metric.data_source = 'database'

          # TODO: replace hardcoded assignments https://gitlab.com/gitlab-org/gitlab/-/issues/464066
          metric.instrumentation_class = 'CountIssuesMetric'
          metric.time_frame = %w[7d 28d]
          metric.key_path = 'issues_count'
        when :event_metric, :aggregate_metric
          prompt_for_events(type)

          return unless @selected_event_paths.any?

          prompt_for_metrics

          return unless metric

          metric.data_source = 'internal_events'
          prompt_for_event_filters
        end
      end

      def prompt_for_events(type)
        return if @selected_event_paths.any?

        new_page!(on_step: 'Config', steps: STEPS)

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

        @metric = cli.select(
          'Which metrics do you want to add?',
          eligible_metrics,
          **select_opts,
          **filter_opts,
          per_page: 20,
          &disabled_format_callback
        )

        assign_shared_attrs(:actions, :milestone) do
          {
            actions: selected_events.map(&:action).sort
          }
        end
      end

      def prompt_for_event_filters
        return unless metric.filters_expected?

        selected_unique_identifier = metric.identifier.value
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

      def file_saved_context_message(attributes)
        format_prefix "  ", <<~TEXT.chomp
          - Visit #{format_info('https://metrics.gitlab.com')} to find dashboard links for this metric
          #{metric_dashboard_links(attributes)}
          - Set up Tableau Alerts via the Metric Trend Dashboards to receive notifications when your metrics cross specified thresholds.
            See the Tableau Documentation for details: #{format_info('https://help.tableau.com/current/pro/desktop/en-us/data_alerts.htm')}
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

        new_page!(on_step: 'Defaults', steps: STEPS)

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
            metric.product_group,
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

      def create_metric_file
        new_page!(on_step: 'Save files', steps: STEPS) # Repeat the same step but increment metric counter

        cli.say show_all_metric_paths(metric)
        cli.say "\n"

        cli.say format_prompt(format_subheader('SAVING FILE', metric.description))
        cli.say "\n"

        prompt_to_save_file(metric.file_path, metric.formatted_output)
      end

      def show_all_metric_paths(metric)
        time_frames = metric.time_frame.value

        return unless time_frames.is_a?(Array) && time_frames.length > 1

        cli.say <<~TEXT
          #{format_info "This would create #{time_frames.length} metrics with the following key paths:"}

          #{time_frames.map do |time_frame|
            "#{TimeFramedKeyPath::METRIC_TIME_FRAME_DESC[time_frame]}: #{format_info(TimeFramedKeyPath.build(metric.key_path, time_frame))}" # {' '}
          end.join("\n")}
        TEXT
      end

      def prompt_for_next_steps(outcome = nil)
        new_page!

        outcome ||= '  No files saved.'

        # TODO: change this message for database metrics https://gitlab.com/gitlab-org/gitlab/-/issues/464066
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

        next_step = get_next_step

        case next_step
        when :new_event
          EventDefiner.new(cli).run
        when :new_metric_with_events
          MetricDefiner.new(cli, @selected_event_paths).run
        when :new_metric
          MetricDefiner.new(cli).run
        when :view_usage
          args = [cli]
          args += [@selected_event_paths.first, selected_events.first] if metric.event_metric?
          UsageViewer.new(*args).run
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

      # Helper for #prompt_for_description
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

      def prompt_for_description
        new_page!(on_step: 'Description', steps: STEPS)

        cli.say DESCRIPTION_INTRO
        cli.say selected_event_descriptions.join if metric.event_metric?

        description_start = format_info("#{metric.description_prefix}...")

        cli.say <<~TEXT

          #{input_opts[:prefix]} How would you describe this metric to a non-technical person? #{input_required_text}

          #{format_info('Technical description:')} #{metric.technical_description}

        TEXT

        # TODO: make the prompt more user friendly for db metrics https://gitlab.com/gitlab-org/gitlab/-/issues/464066

        description = prompt_for_text("  Finish the description: #{description_start}", multiline: true) do |q|
          q.required true
          q.modify :trim
          q.messages[:required?] = DESCRIPTION_HELP
        end

        metric.description = "#{metric.description_prefix} #{description}"
      end

      def prompt_for_metric_name
        name_reason = name_requirement_reason

        return unless name_reason

        default_name = metric.key.value
        display_name = metric.key.value("\e[0m[REPLACE ME]\e[36m")
        empty_name = metric.key.value('')
        max_length = MAX_FILENAME_LENGTH - "#{empty_name}.yml".length
        help_tokens = { name: default_name, count: max_length }

        cli.say <<~TEXT

          #{input_opts[:prefix]} #{name_reason[:text]} How should we refererence this metric? #{input_required_text}

                      ID:  #{format_info(display_name)}
                Filename:  #{format_info(display_name)}#{format_info('.yml')}

        TEXT

        metric.key = prompt_for_text('  Replace with: ', multiline: true) do |q|
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

      # Helper for #prompt_for_description
      def name_requirement_reason
        if metric.filters.assigned?
          NAME_REQUIREMENT_REASONS[:filters]
        elsif metric.file_name.length > MAX_FILENAME_LENGTH
          NAME_REQUIREMENT_REASONS[:length]
        elsif conflicting_key_path?(metric.key_path)
          NAME_REQUIREMENT_REASONS[:conflict]
        end
      end

      # Helper for #prompt_for_description
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

      # Helper for #prompt_for_next_steps
      def get_next_step
        cli.select("How would you like to proceed?", **select_opts) do |menu|
          menu.enum "."

          menu.choice "New Event -- define a new event", :new_event

          if metric.event_metric?
            actions = selected_events.map(&:action).join(', ')
            menu.choice "New Metric -- define another metric for #{actions}", :new_metric_with_events
          end

          menu.choice "New Metric -- define another metric", :new_metric

          if metric.event_metric?
            view_usage_message = "View Usage -- look at code examples for event #{selected_events.first.action}"
            default = view_usage_message
          else
            view_usage_message = "View Usage -- look at code examples"
            default = 'Exit'
          end

          menu.choice view_usage_message, :view_usage
          menu.choice 'Exit', :exit
          menu.default default
        end
      end

      # ----- Shared Helpers ----------------------

      def assign_shared_attrs(...)
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
        metric.bulk_assign(attrs)
      end
    end
  end
end
