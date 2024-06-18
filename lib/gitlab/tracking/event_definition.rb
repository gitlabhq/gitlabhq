# frozen_string_literal: true

module Gitlab
  module Tracking
    InvalidEventError = Class.new(RuntimeError)

    class EventDefinition
      EVENT_SCHEMA_PATH = Rails.root.join('config', 'events', 'schema.json')
      SCHEMA = ::JSONSchemer.schema(EVENT_SCHEMA_PATH)

      attr_reader :path
      attr_reader :attributes

      class << self
        include Gitlab::Utils::StrongMemoize

        def definitions
          @definitions ||= paths.flat_map { |glob_path| load_all_from_path(glob_path) }
        end

        def internal_event_exists?(event_name)
          definitions
            .any? { |event| event.attributes[:internal_events] && event.attributes[:action] == event_name } ||
            Gitlab::UsageDataCounters::HLLRedisCounter.legacy_event?(event_name)
        end

        def find(event_name)
          strong_memoize_with(:find, event_name) do
            definitions.find { |definition| definition.attributes[:action] == event_name }
          end
        end

        private

        def paths
          @paths ||= [Rails.root.join('config', 'events', '*.yml'), Rails.root.join('ee', 'config', 'events', '*.yml')]
        end

        def load_from_file(path)
          definition = File.read(path)
          definition = YAML.safe_load(definition)
          definition.deep_symbolize_keys!

          self.new(path, definition)
        rescue StandardError => e
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(Gitlab::Tracking::InvalidEventError.new(e.message))
        end

        def load_all_from_path(glob_path)
          Dir.glob(glob_path).map { |path| load_from_file(path) }
        end
      end

      def initialize(path, opts = {})
        @path = path
        @attributes = opts
      end

      def to_h
        attributes
      end
      alias_method :to_dictionary, :to_h

      def yaml_path
        path.delete_prefix(Rails.root.to_s)
      end

      def validation_errors
        SCHEMA.validate(attributes.deep_stringify_keys).map do |error|
          <<~ERROR_MSG
            --------------- VALIDATION ERROR ---------------
            Definition file: #{path}
            Error type: #{error['type']}
            Data: #{error['data']}
            Path: #{error['data_pointer']}
            Details: #{error['details']}
          ERROR_MSG
        end
      end

      def event_selection_rules
        @event_selection_rules ||= find_event_selection_rules
      end

      private

      def find_event_selection_rules
        result = [
          Gitlab::Usage::EventSelectionRule.new(name: attributes[:action], time_framed: false),
          Gitlab::Usage::EventSelectionRule.new(name: attributes[:action], time_framed: true)
        ]
        Gitlab::Usage::MetricDefinition.definitions.each_value do |metric_definition|
          matching_event_selection_rules = metric_definition.event_selection_rules.select do |event_selection_rule|
            event_selection_rule.name == attributes[:action]
          end
          result.concat(matching_event_selection_rules)
        end
        result.uniq
      end
    end
  end
end
