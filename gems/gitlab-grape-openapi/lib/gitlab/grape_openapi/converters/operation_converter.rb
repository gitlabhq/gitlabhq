# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Converters
      class OperationConverter
        def self.convert(route, schema_registry)
          new(route, schema_registry).convert
        end

        def initialize(route, schema_registry)
          @route = route
          @schema_registry = schema_registry
          @config = Gitlab::GrapeOpenapi.configuration
        end

        def convert
          Models::Operation.new.tap do |operation|
            operation.operation_id = operation_id
            operation.description = extract_description
            operation.tags = extract_tags
            operation.responses = ResponseConverter.new(@route, @schema_registry).convert
          end
        end

        private

        attr_reader :config, :route, :schema_registry

        def operation_id
          method = http_method.downcase
          normalized = normalized_path
          segments = normalized.split('/').reject(&:empty?)

          parts = segments.filter_map do |seg|
            next 'Dash' if seg == '-'

            if seg.start_with?('{')
              param_name = seg[1..-2]
              camelize(param_name)
            else
              camelize(seg)
            end
          end

          "#{method}#{parts.join}"
        end

        def extract_description
          description_from_options = options[:description]
          return description_from_options[:description] if description_from_options.is_a?(Hash)
          return description_from_options if description_from_options.is_a?(String)

          return unless endpoint

          description_hash = endpoint.instance_variable_get(:@inheritable_setting)&.namespace
          description_hash[:description] if description_hash.is_a?(Hash)
        end

        def extract_tags
          segments = path_segments
          return [] if segments.empty?

          [segments.first]
        end

        def path_segments
          segments = normalized_path.split('/').reject do |segment|
            segment.empty? || segment.start_with?('{')
          end

          segments.reject { |seg| seg == config.api_prefix || seg == config.api_version || seg == '-' }
        end

        def normalized_path
          path = pattern.instance_variable_get(:@origin)
          path
            .gsub(/\(\.:format\)$/, '')
            .gsub(/:\w+/) { |match| "{#{match[1..]}}" }
            .gsub('{version}', config.api_version)
        end

        def camelize(string)
          string.gsub(/[@.-]/, '_').split('_').reject(&:empty?).map(&:capitalize).join
        end

        def http_method
          options[:method]
        end

        def pattern
          route.instance_variable_get(:@pattern)
        end

        def options
          route.instance_variable_get(:@options)
        end

        def endpoint
          route.instance_variable_get(:@app)
        end
      end
    end
  end
end
