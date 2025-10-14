# frozen_string_literal: true

module InternalEventsCli
  module Subflows
    class EventMetricDefiner
      include Helpers
      include Text::MetricDefiner

      attr_reader :metric, :selected_event_paths, :selected_filters

      def initialize(cli, selected_event_paths, type)
        @cli = cli
        @metric = nil
        @selected_event_paths = selected_event_paths
        @selected_filters = {}
        @type = type
      end

      def run
        prompt_for_events

        return unless @selected_event_paths.any?

        prompt_for_metrics

        return unless metric

        metric.data_source = 'internal_events'
        prompt_for_event_filters
      end

      private

      attr_reader :cli, :type

      # ----- Memoization Helpers -----------------

      def events
        @events ||= events_by_filepath(@selected_event_paths)
      end

      def selected_events
        @selected_events ||= events.values_at(*@selected_event_paths)
      end

      # ----- Prompts -----------------------------

      def prompt_for_events
        return if @selected_event_paths.any?

        new_page!(on_step: 'Config', steps: InternalEventsCli::Flows::MetricDefiner::STEPS)

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

        new_page!(on_step: 'Scope', steps: InternalEventsCli::Flows::MetricDefiner::STEPS)

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
