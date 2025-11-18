# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Converters
      class RequestBodyConverter
        DEFAULT_CONTENT_TYPE = 'application/json'
        GET_METHOD = 'GET'
        DELETE_METHOD = 'DELETE'

        attr_reader :route, :options, :params

        def self.convert(route:, options:, params:)
          new(route: route, options: options, params: params).convert
        end

        def initialize(route:, options:, params:)
          @route = route
          @options = options
          @params = params
        end

        def convert
          return nil if route_method == GET_METHOD || route_method == DELETE_METHOD
          return nil if params.empty?

          body_params = extract_body_params
          return nil if body_params.empty?

          build_request_body(body_params)
        end

        private

        def route_method
          options[:method]
        end

        def extract_body_params
          body_params = params.reject do |key, _|
            path_with_params.include?("{#{key}}")
          end

          restructure_nested_params(body_params)
        end

        def path_with_params
          @path_with_params ||= begin
            pattern = route.instance_variable_get(:@pattern)
            path = pattern.instance_variable_get(:@origin)
            path
              .gsub(/\(\.:format\)$/, '')
              .gsub(/:\w+/) { |match| "{#{match[1..]}}" }
          end
        end

        def restructure_nested_params(body_params)
          # Separate root params from nested params (with bracket notation)
          root_params = {}
          nested_map = {}

          body_params.each do |key, param_options|
            key_str = key.to_s
            if key_str.include?('[')
              # Parse bracket notation like "assets[links][name]"
              parts = parse_bracket_notation(key_str)
              nested_map[parts] = param_options
            else
              root_params[key] = param_options
            end
          end

          # Build nested structure
          nested_map.each do |parts, param_options|
            insert_nested_param(root_params, parts, param_options)
          end

          root_params
        end

        def parse_bracket_notation(key)
          key.scan(/\w+/)
        end

        def insert_nested_param(root_params, parts, param_options)
          return if parts.empty?

          first = parts[0]
          rest = parts[1..]

          # Ensure the root param exists as a Hash/object
          root_params[first] ||= { type: 'Hash', required: false }

          if rest.empty?
            # This is a direct property (e.g., just "config")
            # Merge param_options to preserve description and other metadata
            root_params[first] = root_params[first].merge(param_options)
          elsif rest.length == 1
            # This is the parent of the final property (e.g., "assets[links]")
            root_params[first][:params] ||= {}
            root_params[first][:params][rest[0]] = param_options
          else
            # Multiple levels remaining - recurse to handle arbitrary depth
            # (e.g., "config[database][pool][max_connections]")
            root_params[first][:params] ||= {}
            insert_nested_param(root_params[first][:params], rest, param_options)
          end
        end

        def build_request_body(body_params)
          properties = {}
          required_params = []

          body_params.each do |key, param_options|
            schema = build_param_schema(key, param_options)
            properties[key.to_s] = schema
            required_params << key.to_s if param_options[:required]
          end

          schema = {
            type: 'object',
            properties: properties
          }
          schema[:required] = required_params unless required_params.empty?

          {
            required: required_params.any?,
            content: {
              DEFAULT_CONTENT_TYPE => {
                schema: schema
              }
            }
          }
        end

        def build_param_schema(key, param_options)
          type_str = param_options[:type].to_s

          # Handle array types like [String] (single type in brackets)
          if type_str.start_with?('[') && type_str.exclude?(',')
            # This is an array type like [String], not a union type
            return build_simple_array_from_bracket_notation(param_options)
          end

          # Handle union types (e.g., [String, Integer])
          return build_union_type_schema(param_options) if type_str.start_with?('[')

          validations = validations_for(key.to_sym)
          object_type = resolve_param_type(param_options[:type])
          object_format = resolve_param_format(param_options[:type])

          # Handle enum/values
          return build_enum_schema(object_type, param_options) if param_options[:values]

          # Handle array types with nested params
          return build_nested_array_schema(param_options) if param_options[:type] == 'Array' && param_options[:params]

          # Handle array types (simple, like Array[String])
          return build_array_schema(param_options) if object_type.include?('[')

          # Handle Hash types with nested params
          return build_nested_hash_schema(param_options) if param_options[:type] == 'Hash' && param_options[:params]

          # Build basic schema
          build_basic_schema(object_type, object_format, param_options, validations)
        end

        def build_union_type_schema(param_options)
          types = param_options[:type][1..-2].split(", ")
          { oneOf: types.map { |type| { type: TypeResolver.resolve_type(type) } } }
        end

        def build_enum_schema(object_type, param_options)
          schema = { type: object_type, enum: param_options[:values] }
          schema[:description] = param_options[:desc] if param_options[:desc]
          schema
        end

        def build_simple_array_from_bracket_notation(param_options)
          # Handle types like [String] or [Integer]
          item_type = param_options[:type].to_s.delete('[').delete(']')
          schema = { type: 'array', items: { type: TypeResolver.resolve_type(item_type) } }
          schema[:description] = param_options[:desc] if param_options[:desc]
          schema
        end

        def build_array_schema(param_options)
          item_type = param_options[:type].delete('[').delete(']').downcase
          schema = { type: 'array', items: { type: TypeResolver.resolve_type(item_type) } }
          schema[:description] = param_options[:desc] if param_options[:desc]
          schema
        end

        def build_nested_array_schema(param_options)
          schema = { type: 'array' }
          schema[:description] = param_options[:desc] if param_options[:desc]

          # Build the items schema from nested params
          nested_params = param_options[:params]
          if nested_params && !nested_params.empty?
            properties = {}
            required_params = []

            nested_params.each do |nested_key, nested_options|
              properties[nested_key.to_s] = build_param_schema(nested_key, nested_options)
              required_params << nested_key.to_s if nested_options[:required]
            end

            items_schema = {
              type: 'object',
              properties: properties
            }
            items_schema[:required] = required_params unless required_params.empty?

            schema[:items] = items_schema
          else
            # If no nested params, default to object type
            schema[:items] = { type: 'object' }
          end

          schema
        end

        def build_nested_hash_schema(param_options)
          schema = { type: 'object' }
          schema[:description] = param_options[:desc] if param_options[:desc]

          # Build the properties schema from nested params
          nested_params = param_options[:params]
          if nested_params && !nested_params.empty?
            properties = {}
            required_params = []

            nested_params.each do |nested_key, nested_options|
              properties[nested_key.to_s] = build_param_schema(nested_key, nested_options)
              required_params << nested_key.to_s if nested_options[:required]
            end

            schema[:properties] = properties
            schema[:required] = required_params unless required_params.empty?
          end

          schema
        end

        def build_basic_schema(object_type, object_format, param_options, validations)
          schema = { type: object_type }
          schema[:format] = object_format if object_format
          schema[:default] = param_options[:default] if param_options[:default]
          schema[:description] = param_options[:desc] if param_options[:desc]
          schema[:example] = param_options.dig(:documentation, :example) if param_options.dig(:documentation, :example)

          # Add regex validations
          validation = validations&.find { |v| v[:validator_class] == Grape::Validations::Validators::RegexpValidator }
          schema[:pattern] = validation[:options].inspect.delete("/") if validation

          schema
        end

        def resolve_param_type(type)
          return 'string' if type == 'DateTime'

          TypeResolver.resolve_type(type) || 'string'
        end

        def resolve_param_format(type)
          'date-time' if type == 'DateTime'
        end

        def validations_for(attribute)
          route
            .app
            .inheritable_setting
            .namespace_stackable
            .new_values[:validations]
            &.select { |v| v[:attributes].include?(attribute) }
        end
      end
    end
  end
end
