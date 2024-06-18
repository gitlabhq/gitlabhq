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

      def initialize(path, opts = {})
        @path = path
        @attributes = opts
      end

      def key
        @attributes[:key_path]
      end
      alias_method :key_path, :key
      def events
        events_from_new_structure || events_from_old_structure || {}
      end

      def event_selection_rules
        return [] unless @attributes[:events]

        @event_selection_rules ||= @attributes[:events].map do |event|
          EventSelectionRule.new(
            name: event[:name],
            time_framed: time_framed?,
            filter: event[:filter],
            unique_identifier_name: event[:unique]&.split('.')&.first&.to_sym
          )
        end
      end

      def instrumentation_class
        if internal_events?
          events.each_value.first.nil? ? "TotalCountMetric" : "UniqueCountMetric"
        else
          @attributes[:instrumentation_class]
        end
      end

      # This method can be removed when the refactoring is complete. It is only here to
      # limit access to @attributes in a gradual manner.
      def raw_attributes
        @attributes
      end

      def status
        @attributes[:status]
      end

      def value_json_schema
        @attributes[:value_json_schema]
      end

      def value_type
        @attributes[:value_type]
      end

      def to_context
        return unless %w[redis redis_hll].include?(data_source)

        Gitlab::Tracking::ServicePingContext.new(data_source: data_source, event: events.each_key.first)
      end

      def to_h
        @attributes
      end

      def json_schema
        return unless has_json_schema?

        @json_schema ||= Gitlab::Json.parse(File.read(json_schema_path))
      end

      def json_schema_path
        return '' unless has_json_schema?

        Rails.root.join(@attributes[:value_json_schema])
      end

      def has_json_schema?
        @attributes[:value_type] == 'object' && @attributes[:value_json_schema].present?
      end

      def validation_errors
        SCHEMA.validate(@attributes.deep_stringify_keys).map do |error|
          <<~ERROR_MSG
            --------------- VALIDATION ERROR ---------------
            Metric file: #{path}
            Error type: #{error['type']}
            Data: #{error['data']}
            Path: #{error['data_pointer']}
          ERROR_MSG
        end
      end

      def product_group
        @attributes[:product_group]
      end

      def time_frame
        @attributes[:time_frame]
      end

      def time_framed?
        %w[7d 28d].include?(time_frame)
      end

      def active?
        status == 'active'
      end

      def broken?
        status == 'broken'
      end

      def available?
        AVAILABLE_STATUSES.include?(status)
      end

      def valid_service_ping_status?
        VALID_SERVICE_PING_STATUSES.include?(status)
      end

      def data_category
        @attributes[:data_category]
      end

      def data_source
        @attributes[:data_source]
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
          all.select { |definition| definition.status != 'removed' }.index_by(&:key_path)
        end

        def with_instrumentation_class
          all.select do |definition|
            (definition.internal_events? || definition.instrumentation_class.present?) && definition.available?
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

          self.new(path, definition)
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

      def events_from_new_structure
        events = @attributes[:events]
        return unless events

        events.to_h { |event| [event[:name], event[:unique]&.to_sym] }
      end

      def events_from_old_structure
        options_events = @attributes.dig(:options, :events)
        return unless options_events

        options_events.index_with { nil }
      end
    end
  end
end

Gitlab::Usage::MetricDefinition.prepend_mod_with('Gitlab::Usage::MetricDefinition')
