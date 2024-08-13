# frozen_string_literal: true

# Helpers related to listing existing metric definitions
module InternalEventsCli
  module Helpers
    module MetricOptions
      EVENT_PHRASES = {
        'user' => "who triggered %s",
        'namespace' => "where %s occurred",
        'project' => "where %s occurred",
        nil => "%s occurrences"
      }.freeze

      # Creates a list of metrics to be used as options in a
      # select/multiselect menu; existing metrics and metrics for
      # unavailable identifiers are marked as disabled
      #
      # @param events [Array<ExistingEvent>]
      # @return [Array<Hash>] hash (compact) has keys/values:
      #   value: [Array<NewMetric>]
      #   name: [String] formatted description of the metrics
      #   disabled: [String] reason metrics are disabled
      def get_metric_options(events)
        actions = events.map(&:action)
        options = get_all_metric_options(actions)
        identifiers = get_identifiers_for_events(events)
        metric_name = format_metric_name_for_events(events)
        filter_name = format_filter_options_for_events(events)

        options.reject!(&:filters_expected?) unless filter_name

        options = options.group_by do |metric|
          [
            metric.identifier.value,
            conflicting_metric_exists?(metric),
            metric.filters_expected?,
            metric.time_frame.value == 'all'
          ]
        end

        options.map do |(identifier, defined, filtered, _), metrics|
          format_metric_option(
            identifier,
            metric_name,
            (filter_name if filtered),
            metrics,
            defined: defined,
            supported: [*identifiers, nil].include?(identifier)
          )
        end
      end

      private

      # Lists all potential metrics supported in service ping,
      # ordered by: identifier > filters > time_frame
      #
      # @param actions [Array<String>] event names
      # @return [Array<NewMetric>]
      def get_all_metric_options(actions)
        [
          Metric.new(actions: actions, time_frame: '28d', identifier: 'user'),
          Metric.new(actions: actions, time_frame: '7d', identifier: 'user'),
          Metric.new(actions: actions, time_frame: '28d', identifier: 'user', filters: []),
          Metric.new(actions: actions, time_frame: '7d', identifier: 'user', filters: []),
          Metric.new(actions: actions, time_frame: '28d', identifier: 'project'),
          Metric.new(actions: actions, time_frame: '7d', identifier: 'project'),
          Metric.new(actions: actions, time_frame: '28d', identifier: 'project', filters: []),
          Metric.new(actions: actions, time_frame: '7d', identifier: 'project', filters: []),
          Metric.new(actions: actions, time_frame: '28d', identifier: 'namespace'),
          Metric.new(actions: actions, time_frame: '7d', identifier: 'namespace'),
          Metric.new(actions: actions, time_frame: '28d', identifier: 'namespace', filters: []),
          Metric.new(actions: actions, time_frame: '7d', identifier: 'namespace', filters: []),
          Metric.new(actions: actions, time_frame: '28d'),
          Metric.new(actions: actions, time_frame: '7d'),
          Metric.new(actions: actions, time_frame: '28d', filters: []),
          Metric.new(actions: actions, time_frame: '7d', filters: []),
          Metric.new(actions: actions, time_frame: 'all'),
          Metric.new(actions: actions, time_frame: 'all', filters: [])
        ]
      end

      # Very brief summary of the provided events to use in a basic
      # description of the metric; does not account for filters
      #
      # @param events [Array<ExistingEvent>]
      # @return [String]
      def format_metric_name_for_events(events)
        return events.first.action if events.length == 1

        "any of #{events.length} events"
      end

      # Formats the list of the additional properties available
      # across any of the events
      #
      # @param events [Array<ExistingEvent>]
      # @return [String] ex) "label/property"
      def format_filter_options_for_events(events)
        available_filters = events.flat_map(&:available_filters).uniq

        available_filters.join('/') if available_filters.any?
      end

      # Get only the identifiers in common for all events
      #
      # @param events [Array<ExistingEvent>]
      # @return [Array<String>]
      def get_identifiers_for_events(events)
        events.map(&:identifiers).reduce(&:&)
      end

      # Checks if there's an existing metric which has the same
      # properties as the new one
      #
      # @param new_metric [NewMetric]
      # @return [Boolean]
      def conflicting_metric_exists?(new_metric)
        # metrics with filters are conflict-free until new filters are defined
        return false if new_metric.filters_expected?

        cli.global.metrics.any? do |existing_metric|
          existing_metric.actions == new_metric.actions &&
            existing_metric.time_frame == new_metric.time_frame.value &&
            existing_metric.identifier == new_metric.identifier.value &&
            !existing_metric.filtered?
        end
      end

      # Formats & assembles a single select/multiselect menu item,
      #
      # @param identifier [String] user/project/namespace (must support unique metrics)
      # @param event_name [String]
      # @param filter_name [String]
      # @param metrics [Array<NewMetric>]
      # @option defined [Boolean]
      # @option supported [Boolean]
      # @return [Hash] see #get_metric_options for format
      def format_metric_option(identifier, event_name, filter_name, metrics, defined:, supported:)
        time_frame = metrics.map { |metric| metric.time_frame.description }.join('/')
        unique_by = "unique #{identifier}s " if identifier
        event_phrase = EVENT_PHRASES[identifier] % event_name
        filter_phrase = " where filtered" if filter_name

        if supported && !defined
          filter_phrase = " #{format_info('where')} #{filter_name} is..." if filter_name
          time_frame = format_info(time_frame)
          unique_by = format_info(unique_by)
        end

        name = "#{time_frame} count of #{unique_by}[#{event_phrase}]#{filter_phrase}"

        if supported && defined
          disabled = format_warning("(already defined)")
          name = format_help(name)
        elsif !supported
          disabled = format_warning("(#{identifier} unavailable)")
          name = format_help(name)
        end

        { name: name, value: metrics, disabled: disabled }.compact
      end
    end
  end
end
