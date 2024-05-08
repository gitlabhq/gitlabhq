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
        def paths
          @paths ||= [Rails.root.join('config', 'events', '*.yml'), Rails.root.join('ee', 'config', 'events', '*.yml')]
        end

        def definitions
          paths.flat_map { |glob_path| load_all_from_path(glob_path) }
        end

        def find(event_name)
          definitions.find { |definition| definition.attributes[:action] == event_name }
        end

        private

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
          ERROR_MSG
        end
      end

      def event_selection_rules
        result = [
          { name: attributes[:action], time_framed?: false, filter: {} },
          { name: attributes[:action], time_framed?: true, filter: {} }
        ]
        Gitlab::Usage::MetricDefinition.definitions.each_value do |metric_definition|
          metric_definition.attributes[:events]&.each do |event_selection_rule|
            if event_selection_rule[:name] == attributes[:action]
              result << {
                name: attributes[:action],
                time_framed?: %w[7d 28d].include?(metric_definition.attributes[:time_frame]),
                filter: event_selection_rule[:filter] || {}
              }
            end
          end
        end
        result.uniq
      end
    end
  end
end
