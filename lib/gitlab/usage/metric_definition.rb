# frozen_string_literal: true

module Gitlab
  module Usage
    class MetricDefinition
      METRIC_SCHEMA_PATH = Rails.root.join('config', 'metrics', 'schema.json')
      BASE_REPO_PATH = 'https://gitlab.com/gitlab-org/gitlab/-/blob/master'
      SKIP_VALIDATION_STATUSES = %w[deprecated removed].to_set.freeze

      attr_reader :path
      attr_reader :attributes

      def initialize(path, opts = {})
        @path = path
        @attributes = opts
      end

      def key
        key_path
      end

      def to_h
        attributes
      end

      def json_schema_path
        return '' unless has_json_schema?

        "#{BASE_REPO_PATH}/#{attributes[:value_json_schema]}"
      end

      def has_json_schema?
        attributes[:value_type] == 'object' && attributes[:value_json_schema].present?
      end

      def yaml_path
        "#{BASE_REPO_PATH}#{path.delete_prefix(Rails.root.to_s)}"
      end

      def validate!
        unless skip_validation?
          self.class.schemer.validate(attributes.stringify_keys).each do |error|
            error_message = <<~ERROR_MSG
              Error type: #{error['type']}
              Data: #{error['data']}
              Path: #{error['data_pointer']}
              Details: #{error['details']}
              Metric file: #{path}
            ERROR_MSG

            Gitlab::ErrorTracking.track_and_raise_for_dev_exception(Gitlab::Usage::Metric::InvalidMetricError.new(error_message))
          end
        end
      end

      alias_method :to_dictionary, :to_h

      class << self
        def paths
          @paths ||= [Rails.root.join('config', 'metrics', '[^agg]*', '*.yml')]
        end

        def definitions(skip_validation: false)
          @skip_validation = skip_validation
          @definitions ||= load_all!
        end

        def all
          @all ||= definitions.map { |_key_path, definition| definition }
        end

        def schemer
          @schemer ||= ::JSONSchemer.schema(Pathname.new(METRIC_SCHEMA_PATH))
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

          self.new(path, definition).tap(&:validate!)
        rescue StandardError => e
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(Gitlab::Usage::Metric::InvalidMetricError.new(e.message))
        end

        def load_all_from_path!(definitions, glob_path)
          Dir.glob(glob_path).each do |path|
            definition = load_from_file(path)

            if previous = definitions[definition.key]
              Gitlab::ErrorTracking.track_and_raise_for_dev_exception(Gitlab::Usage::Metric::InvalidMetricError.new("Metric '#{definition.key}' is already defined in '#{previous.path}'"))
            end

            definitions[definition.key] = definition
          end
        end
      end

      private

      def method_missing(method, *args)
        attributes[method] || super
      end

      def skip_validation?
        !!attributes[:skip_validation] || @skip_validation || SKIP_VALIDATION_STATUSES.include?(attributes[:status])
      end
    end
  end
end

Gitlab::Usage::MetricDefinition.prepend_mod_with('Gitlab::Usage::MetricDefinition')
