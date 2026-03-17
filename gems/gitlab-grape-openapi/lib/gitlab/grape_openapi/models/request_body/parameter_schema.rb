# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Models
      module RequestBody
        class ParameterSchema
          include Converters::CoercerResolver
          include Concerns::Serializable

          attr_reader :route

          def initialize(route:)
            @route = route
          end

          def build(key, param_options)
            validations = validations_for(key.to_sym)
            built_schema = build_raw_type_schema(param_options, validations)

            unless built_schema
              object_type = Converters::TypeResolver.resolve_type(param_options[:type]) || 'string'
              object_format = Converters::TypeResolver.resolve_format(nil, param_options[:type])
              built_schema = build_resolved_schema(object_type, object_format, param_options, validations)
            end

            apply_allow_blank(built_schema, param_options)
            built_schema
          end

          # Handles schema building for types that cannot safely be passed through TypeResolver
          def build_raw_type_schema(param_options, validations)
            type_str = param_options[:type].to_s
            mapping = coercer_mapping_for(validations)

            if mapping
              # Handle coerced types(e.g., coerce_with: option used)
              build_coerced_schema_with_description(mapping, param_options)
            elsif type_str.start_with?('[') && type_str.exclude?(',')
              # Handle array types like [String] (single type in brackets)
              build_simple_array_from_bracket_notation(param_options)
            elsif type_str.include?('API::Validations::Types::WorkhorseFile')
              # Handle file types (e.g., API::Validations::Types::WorkhorseFile)
              build_file_schema(param_options)
            elsif type_str.start_with?('[')
              # Handle union types (e.g., [String, Integer])
              build_union_type_schema(param_options)
            end
          end

          # Handles schema building for types that have been resolved through TypeResolver
          def build_resolved_schema(object_type, object_format, param_options, validations)
            if param_options[:values].is_a?(Range)
              # Handle range values
              build_range_schema(object_type, param_options)
            elsif param_options[:values]
              # Handle enum/values
              build_enum_schema(object_type, param_options)
            elsif param_options[:type] == 'Array' && param_options[:params]
              # Handle array types with nested params
              build_nested_array_schema(param_options)
            elsif object_type.include?('[')
              # Handle array types (simple, like Array[String])
              build_array_schema(param_options)
            elsif param_options[:type] == 'Hash' && param_options[:params]
              # Handle Hash types with nested params
              build_nested_hash_schema(param_options)
            else
              # Build basic schema
              build_basic_schema(object_type, object_format, param_options, validations)
            end
          end

          def build_coerced_schema_with_description(mapping, param_options)
            schema = build_coerced_schema(mapping)
            schema[:description] = param_options[:desc] if param_options[:desc]
            schema
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
            { oneOf: types.map { |type| Converters::TypeResolver.resolve_union_member(type) } }
          end

          def build_range_schema(object_type, param_options)
            range = param_options[:values]
            schema = { type: object_type }
            schema[:minimum] = range.begin if range.begin
            schema[:maximum] = range.end if range.end
            if param_options[:default] && serializable?(param_options[:default])
              schema[:default] = param_options[:default]
            end

            schema[:description] = param_options[:desc] if param_options[:desc]
            schema
          end

          def build_enum_schema(object_type, param_options)
            schema = { type: object_type }
            schema[:enum] = param_options[:values] unless param_options[:values].is_a?(Proc)
            if param_options[:default] && serializable?(param_options[:default])
              schema[:default] = param_options[:default]
            end

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
            if param_options[:default] && serializable?(param_options[:default])
              schema[:default] = param_options[:default]
            end

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

          private

          def apply_allow_blank(schema, param_options)
            if param_options[:allow_blank] == false || (param_options[:required] && param_options[:values])
              schema[:minLength] = 1 if schema[:type] == 'string'
            else
              schema[:nullable] = true
            end
          end
        end
      end
    end
  end
end
