# frozen_string_literal: true

module Gitlab
  module Usage
    class MetricDefinition
      METRIC_SCHEMA_PATH = Rails.root.join('config', 'metrics', 'schema', 'base.json')
      SCHEMA = ::JSONSchemer.schema(METRIC_SCHEMA_PATH)
      AVAILABLE_STATUSES = %w[active broken].to_set.freeze
      VALID_SERVICE_PING_STATUSES = %w[active broken].to_set.freeze

      InvalidError = Class.new(RuntimeError)

      attr_reader :path
      attr_reader :attributes

      def initialize(path, opts = {})
        @path = path
        @attributes = opts
      end

      def key
        key_path
      end

      def events
        events_from_new_structure || events_from_old_structure || {}
      end

      def instrumentation_class
        if internal_events?
          events.each_value.first.nil? ? "TotalCountMetric" : "RedisHLLMetric"
        else
          attributes[:instrumentation_class]
        end
      end

      def to_context
        return unless %w[redis redis_hll].include?(data_source)

        Gitlab::Tracking::ServicePingContext.new(data_source: data_source, event: events.each_key.first)
      end

      def to_h
        attributes
      end

      def json_schema
        return unless has_json_schema?

        @json_schema ||= Gitlab::Json.parse(File.read(json_schema_path))
      end

      def json_schema_path
        return '' unless has_json_schema?

        Rails.root.join(attributes[:value_json_schema])
      end

      def has_json_schema?
        attributes[:value_type] == 'object' && attributes[:value_json_schema].present?
      end

      def validation_errors
        SCHEMA.validate(attributes.deep_stringify_keys).map do |error|
          <<~ERROR_MSG
            --------------- VALIDATION ERROR ---------------
            Metric file: #{path}
            Error type: #{error['type']}
            Data: #{error['data']}
            Path: #{error['data_pointer']}
          ERROR_MSG
        end
      end

      def category_to_lowercase
        attributes[:data_category]&.downcase!
      end

      def available?
        AVAILABLE_STATUSES.include?(attributes[:status])
      end

      def valid_service_ping_status?
        VALID_SERVICE_PING_STATUSES.include?(attributes[:status])
      end

      def internal_events?
        data_source == 'internal_events'
      end

      alias_method :to_dictionary, :to_h

      class << self
        def paths
          @paths ||= [Rails.root.join('config', 'metrics', '[^agg]*', '*.yml')]
        end

        def definitions
          @definitions ||= load_all!
        end

        def all
          @all ||= definitions.map { |_key_path, definition| definition }
        end

        def not_removed
          all.select { |definition| definition.attributes[:status] != 'removed' }.index_by(&:key_path)
        end

        def with_instrumentation_class
          all.select do |definition|
            (definition.internal_events? || definition.attributes[:instrumentation_class].present?) && definition.available?
          end
        end

        def context_for(key_path)
          definitions[key_path]&.to_context
        end

        def dump_metrics_yaml
          @metrics_yaml ||= definitions.values.map(&:to_h).map(&:deep_stringify_keys).to_yaml
        end

        private

        def load_all!
          paths.each_with_object({}) do |glob_path, definitions|
            load_all_from_path!(definitions, glob_path)
          end
        end

        def load_from_file(path)
          definition = File.read(path)
          definition = YAML.safe_load(definition)
          definition.deep_symbolize_keys!

          self.new(path, definition).tap(&:category_to_lowercase)
        rescue StandardError => e
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(InvalidError.new(e.message))
        end

        def load_all_from_path!(definitions, glob_path)
          Dir.glob(glob_path).each do |path|
            definition = load_from_file(path)

            if previous = definitions[definition.key]
              Gitlab::ErrorTracking.track_and_raise_for_dev_exception(InvalidError.new("Metric '#{definition.key}' is already defined in '#{previous.path}'"))
            end

            definitions[definition.key] = definition
          end
        end
      end

      private

      def method_missing(method, *args)
        attributes[method] || super
      end

      def respond_to_missing?(method, *args)
        attributes[method].present? || super
      end

      def events_from_new_structure
        events = attributes[:events]
        return unless events

        events.to_h { |event| [event[:name], event[:unique]&.to_sym] }
      end

      def events_from_old_structure
        options_events = attributes.dig(:options, :events)
        return unless options_events

        options_events.index_with { nil }
      end
    end
  end
end

Gitlab::Usage::MetricDefinition.prepend_mod_with('Gitlab::Usage::MetricDefinition')
