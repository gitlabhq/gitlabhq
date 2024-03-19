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

      def get_metric_options(events)
        options = get_all_metric_options
        identifiers = get_identifiers_for_events(events)
        existing_metrics = get_existing_metrics_for_events(events)
        metric_name = format_metric_name_for_events(events)

        options = options.group_by do |metric|
          [
            metric.identifier,
            metric_already_exists?(existing_metrics, metric),
            metric.time_frame == 'all'
          ]
        end

        options.map do |(identifier, defined, _), metrics|
          format_metric_option(
            identifier,
            metric_name,
            metrics,
            defined: defined,
            supported: [*identifiers, nil].include?(identifier)
          )
        end
      end

      private

      def get_all_metric_options
        [
          Metric.new(time_frame: '28d', identifier: 'user'),
          Metric.new(time_frame: '7d', identifier: 'user'),
          Metric.new(time_frame: '28d', identifier: 'project'),
          Metric.new(time_frame: '7d', identifier: 'project'),
          Metric.new(time_frame: '28d', identifier: 'namespace'),
          Metric.new(time_frame: '7d', identifier: 'namespace'),
          Metric.new(time_frame: '28d'),
          Metric.new(time_frame: '7d'),
          Metric.new(time_frame: 'all')
        ]
      end

      def load_metric_paths
        [
          Dir["config/metrics/counts_all/*.yml"],
          Dir["config/metrics/counts_7d/*.yml"],
          Dir["config/metrics/counts_28d/*.yml"],
          Dir["ee/config/metrics/counts_all/*.yml"],
          Dir["ee/config/metrics/counts_7d/*.yml"],
          Dir["ee/config/metrics/counts_28d/*.yml"]
        ].flatten
      end

      def get_existing_metrics_for_events(events)
        actions = events.map(&:action).sort

        load_metric_paths.filter_map do |path|
          details = YAML.safe_load(File.read(path))
          fields = InternalEventsCli::NEW_METRIC_FIELDS.map(&:to_s)

          metric = Metric.new(**details.slice(*fields))

          metric_actions = metric.events&.map { |event| event['name'] }
          next unless metric_actions

          metric if (metric_actions & actions).any?
        end
      end

      def format_metric_name_for_events(events)
        return events.first.action if events.length == 1

        "any of #{events.length} events"
      end

      # Get only the identifiers in common for all events
      def get_identifiers_for_events(events)
        events.map(&:identifiers).reduce(&:&) || []
      end

      def metric_already_exists?(existing_metrics, metric)
        existing_metrics.any? do |existing_metric|
          time_frame = existing_metric.time_frame || 'all'
          identifier = existing_metric.events&.dig(0, 'unique')&.chomp('.id')

          metric.time_frame == time_frame && metric.identifier == identifier
        end
      end

      def format_metric_option(identifier, event_name, metrics, defined:, supported:)
        time_frame = metrics.map(&:time_frame_prefix).join('/')
        unique_by = "unique #{identifier}s " if identifier
        event_phrase = EVENT_PHRASES[identifier] % event_name

        if supported && !defined
          time_frame = format_info(time_frame)
          unique_by = format_info(unique_by)
        end

        name = "#{time_frame} count of #{unique_by}[#{event_phrase}]"

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
