# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Models
      module RequestBody
        class ParameterSchema
          attr_reader :route

          def initialize(route:)
            @route = route
          end

          def build(key, param_options)
            type_str = param_options[:type].to_s

            # Handle array types like [String] (single type in brackets)
            if type_str.start_with?('[') && type_str.exclude?(',')
              # This is an array type like [String], not a union type
              return build_simple_array_from_bracket_notation(param_options)
            end

            # Handle file types (e.g., API::Validations::Types::WorkhorseFile)
            return build_file_schema(param_options) if type_str.include?('API::Validations::Types::WorkhorseFile')

            # Handle union types (e.g., [String, Integer])
            return build_union_type_schema(param_options) if type_str.start_with?('[')

            validations = validations_for(key.to_sym)
            object_type = resolve_param_type(param_options[:type])
            object_format = resolve_param_format(param_options[:type])

            # Handle range values
            return build_range_schema(object_type, param_options) if param_options[:values].is_a?(Range)

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

          def build_simple_array_from_bracket_notation(param_options)
            # Handle types like [String] or [Integer]
            item_type = param_options[:type].to_s.delete('[').delete(']')
            schema = { type: 'array', items: { type: Converters::TypeResolver.resolve_type(item_type) } }
            schema[:description] = param_options[:desc] if param_options[:desc]
            schema
          end

          def build_file_schema(param_options)
            schema = { type: 'string', format: 'binary' }
            schema[:description] = param_options[:desc] if param_options[:desc]
            schema
          end

          def build_union_type_schema(param_options)
            types = param_options[:type][1..-2].split(", ")
            { oneOf: types.map { |type| { type: Converters::TypeResolver.resolve_type(type) } } }
          end

          def build_range_schema(object_type, param_options)
            range = param_options[:values]
            schema = { type: object_type }
            schema[:minimum] = range.begin if range.begin
            schema[:maximum] = range.end if range.end
            schema[:description] = param_options[:desc] if param_options[:desc]
            schema
          end

          def build_enum_schema(object_type, param_options)
            schema = { type: object_type }
            schema[:enum] = param_options[:values] unless param_options[:values].is_a?(Proc)
            schema[:description] = param_options[:desc] if param_options[:desc]
            schema
          end

          def build_array_schema(param_options)
            item_type = param_options[:type].delete('[').delete(']').downcase
            schema = { type: 'array', items: { type: Converters::TypeResolver.resolve_type(item_type) } }
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
                properties[nested_key.to_s] = build(nested_key, nested_options)
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
                properties[nested_key.to_s] = build(nested_key, nested_options)
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
            default_is_proc = param_options[:default].is_a?(Proc)
            schema[:default] = param_options[:default] if param_options[:default] && !default_is_proc
            schema[:description] = param_options[:desc] if param_options[:desc]

            if param_options.dig(:documentation, :example)
              schema[:example] = param_options.dig(:documentation, :example)
            end

            # Add regex validations
            validation = validations&.find do |v|
              v[:validator_class] == Grape::Validations::Validators::RegexpValidator
            end

            schema[:pattern] = validation[:options].inspect.delete("/") if validation

            schema
          end

          def validations_for(attribute)
            route
              .app
              .inheritable_setting
              .namespace_stackable
              .new_values[:validations]
              &.select { |v| v[:attributes].include?(attribute) }
          end

          def resolve_param_type(type)
            return 'string' if type == 'DateTime'

            Converters::TypeResolver.resolve_type(type) || 'string'
          end

          def resolve_param_format(type)
            'date-time' if type == 'DateTime'
          end
        end
      end
    end
  end
end
