# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Converters
      class OperationConverter
        # https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.0.md#operation-object

        DASH_SEGMENT = 'Dash'

        def self.convert(route, schema_registry)
          new(route, schema_registry).convert
        end

        def initialize(route, schema_registry)
          @route = route
          @schema_registry = schema_registry
          @config = Gitlab::GrapeOpenapi.configuration
          @options = route.instance_variable_get(:@options)
          @pattern = route.instance_variable_get(:@pattern)
          @endpoint = route.instance_variable_get(:@app)
        end

        def convert
          Models::Operation.new.tap do |operation|
            operation.operation_id = operation_id
            operation.summary = extract_description
            operation.description = extract_detail
            operation.tags = extract_tags
            operation.parameters = extract_parameters
            operation.responses = ResponseConverter.new(@route, @schema_registry).convert
            operation.request_body = extract_request_body || {}
          end
        end

        private

        attr_reader :config, :route, :options, :pattern, :endpoint, :schema_registry

        def route_method
          options = @route.instance_variable_get(:@options)
          options[:method]
        end

        def extract_parameters
          return [] if options[:params].empty?

          # For non-GET requests, only path parameters are included here
          # Body parameters are handled separately in extract_request_body
          options[:params].filter_map do |key, options|
            Converters::ParameterConverter.convert(key, options: options, validations: validations_for(key.to_sym),
              route: route)
          end
        end

        def operation_id
          method = http_method.downcase
          normalized = normalized_path
          segments = normalized.split('/').reject(&:empty?)

          parts = segments.filter_map do |seg|
            next DASH_SEGMENT if seg == '-'

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

        def extract_detail
          options.dig(:settings, :description, :detail)
        end

        def extract_tags
          @route.settings.dig(:description, :tags)
        end

        def path_segments
          segments = normalized_path.split('/').reject do |segment|
            segment.empty? || segment.start_with?('{')
          end

          segments.reject { |seg| seg == config.api_prefix || seg == config.api_version || seg == '-' }
        end

        def normalized_path
          @normalized_path ||= begin
            path = normalize_path_pattern
            path.gsub('{version}', config.api_version)
          end
        end

        def normalize_path_pattern
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

        # Get all validations for a single attribute
        # Looks something like:
        # [{:attributes=>[:version_prefix],
        #   :options=>/^[\d+.]+/,
        #   :required=>false,
        #   :params_scope=>#<Grape::Validations::ParamsScope:0x000000016dc35820
        #   :opts=>{:allow_blank=>nil, :fail_fast=>false},
        #   :validator_class=>Grape::Validations::Validators::RegexpValidator}]
        def validations_for(attribute)
          route
            .app
            .inheritable_setting
            .namespace_stackable
            .new_values[:validations]
            &.select { |v| v[:attributes].include?(attribute) }
        end

        def extract_request_body
          RequestBodyConverter.convert(
            route: route,
            options: options,
            params: options[:params]
          )
        end
      end
    end
  end
end
