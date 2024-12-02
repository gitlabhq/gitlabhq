# frozen_string_literal: true

# Helpers for shared  & state across all CLI flows
module InternalEventsCli
  class GlobalState
    def events
      @events ||= load_definitions(
        Event,
        InternalEventsCli::NEW_EVENT_FIELDS,
        all_event_paths
      )
    end

    def metrics
      @metrics ||= begin
        loaded_files = load_definitions(
          Metric,
          InternalEventsCli::NEW_METRIC_FIELDS,
          all_metric_paths
        )
        loaded_files.flat_map do |metric|
          # copy logic of Gitlab::Usage::MetricDefinition
          next metric unless metric.time_frame.is_a?(Array)

          metric.time_frame.map do |time_frame|
            current_metric = metric.dup
            current_metric.time_frame = time_frame
            current_metric.key_path = TimeFramedKeyPath.build(current_metric.key_path, time_frame)
            current_metric
          end
        end
      end
    end

    def reload_definitions
      @events = nil
      @metrics = nil
    end

    private

    def all_event_paths
      [
        Dir["config/events/*.yml"],
        Dir["ee/config/events/*.yml"]
      ].flatten
    end

    def all_metric_paths
      [
        Dir["config/metrics/counts_all/*.yml"],
        Dir["config/metrics/counts_7d/*.yml"],
        Dir["config/metrics/counts_28d/*.yml"],
        Dir["ee/config/metrics/counts_all/*.yml"],
        Dir["ee/config/metrics/counts_7d/*.yml"],
        Dir["ee/config/metrics/counts_28d/*.yml"]
      ].flatten
    end

    def load_definitions(klass, fields, paths)
      paths.filter_map do |path|
        details = YAML.safe_load(File.read(path))
        relevant_fields = fields.map(&:to_s)

        klass.parse(**details.slice(*relevant_fields), file_path: path)
      rescue StandardError => e
        puts "\n\n\e[31mEncountered an error while loading #{path}: #{e.message}\e[0m\n\n\n"
      end
    end
  end
end
