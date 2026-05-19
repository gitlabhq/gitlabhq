# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Models
      module RequestBody
        class ParameterSchema
          include Converters::CoercerResolver
          include Concerns::Serializable
          include Concerns::LimitResolver
          include Concerns::FailFastAnnotatable
          include Concerns::RegexConverter

          def initialize(route:, key:, param_options:)
            @route = route
            @key = key
            @param_options = param_options
            @validations = validations_for(key.to_sym)
          end

          def build
            fail_fast = fail_fast_in_validations?(validations)
            @param_options = param_options.merge(fail_fast: fail_fast) if fail_fast
            built_schema = build_raw_type_schema

            unless built_schema
              object_type = Converters::TypeResolver.resolve_type(param_options[:type]) || 'string'
              object_format = Converters::TypeResolver.resolve_format(nil, param_options[:type])
              built_schema = build_resolved_schema(object_type, object_format)
            end

            apply_allow_blank(built_schema)
            apply_limit!(built_schema, validations)
            built_schema
          end

          private

          attr_reader :route, :key, :param_options, :validations

          def annotated_description
            return param_options[:desc] unless param_options[:fail_fast]

            annotate_fail_fast(param_options[:desc])
          end

          # Handles schema building for types that cannot safely be passed through TypeResolver
          def build_raw_type_schema
            type_str = param_options[:type].to_s
            mapping = coercer_mapping_for(validations)

            if mapping
              # Handle coerced types(e.g., coerce_with: option used)
              build_coerced_schema_with_description(mapping)
            elsif type_str.start_with?('[') && type_str.exclude?(',')
              # Handle array types like [String] (single type in brackets)
              build_simple_array_from_bracket_notation
            elsif type_str.include?('API::Validations::Types::WorkhorseFile')
              # Handle file types (e.g., API::Validations::Types::WorkhorseFile)
              build_file_schema
            elsif type_str.start_with?('[')
              # Handle union types (e.g., [String, Integer])
              build_union_type_schema
            end
          end

          # Handles schema building for types that have been resolved through TypeResolver
          def build_resolved_schema(object_type, object_format)
            if param_options[:values].is_a?(Range)
              # Handle range values
              build_range_schema(object_type)
            elsif param_options[:values]
              # Handle enum/values
              build_enum_schema(object_type)
            elsif param_options[:type] == 'Array' && param_options[:params]
              # Handle array types with nested params
              build_nested_array_schema
            elsif object_type.include?('[')
              # Handle array types (simple, like Array[String])
              build_array_schema
            elsif param_options[:type] == 'Hash' && param_options[:params]
              # Handle Hash types with nested params
              build_nested_hash_schema
            else
              # Build basic schema
              build_basic_schema(object_type, object_format)
            end
          end

          def build_coerced_schema_with_description(mapping)
            schema = build_coerced_schema(mapping)
            schema[:description] = annotated_description if param_options[:desc]
            schema
          end

          def build_simple_array_from_bracket_notation
            # Handle types like [String] or [Integer]
            item_type = param_options[:type].to_s.delete('[').delete(']')
            schema = { type: 'array', items: { type: Converters::TypeResolver.resolve_type(item_type) } }
            schema[:description] = annotated_description if param_options[:desc]
            schema
          end

          def build_file_schema
            schema = { type: 'string', format: 'binary' }
            schema[:description] = annotated_description if param_options[:desc]
            schema
          end

          def build_union_type_schema
            types = param_options[:type][1..-2].split(", ")
            { oneOf: types.map { |type| Converters::TypeResolver.resolve_union_member(type) } }
          end

          def build_range_schema(object_type)
            range = param_options[:values]
            schema = { type: object_type }
            schema[:minimum] = range.begin if range.begin
            schema[:maximum] = range.end if range.end
            if param_options[:default] && serializable?(param_options[:default])
              schema[:default] = param_options[:default]
            end

            schema[:description] = annotated_description if param_options[:desc]
            schema
          end

          def build_enum_schema(object_type)
            schema = { type: object_type }
            schema[:enum] = param_options[:values] unless param_options[:values].is_a?(Proc)
            if param_options[:default] && serializable?(param_options[:default])
              schema[:default] = param_options[:default]
            end

            schema[:description] = annotated_description if param_options[:desc]
            schema
          end

          def build_array_schema
            item_type = param_options[:type].delete('[').delete(']').downcase
            schema = { type: 'array', items: { type: Converters::TypeResolver.resolve_type(item_type) } }
            schema[:description] = annotated_description if param_options[:desc]
            schema
          end

          def build_nested_array_schema
            schema = { type: 'array' }
            schema[:description] = annotated_description if param_options[:desc]

            # Build the items schema from nested params
            nested_params = param_options[:params]
            if nested_params && !nested_params.empty?
              properties = {}
              required_params = []

              nested_params.each do |nested_key, nested_options|
                properties[nested_key.to_s] = self.class.new(
                  route: route, key: nested_key, param_options: nested_options
                ).build
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

          def build_nested_hash_schema
            schema = { type: 'object' }
            schema[:description] = annotated_description if param_options[:desc]

            # Build the properties schema from nested params
            nested_params = param_options[:params]
            if nested_params && !nested_params.empty?
              properties = {}
              required_params = []

              nested_params.each do |nested_key, nested_options|
                properties[nested_key.to_s] = self.class.new(
                  route: route, key: nested_key, param_options: nested_options
                ).build
                required_params << nested_key.to_s if nested_options[:required]
              end

              schema[:properties] = properties
              schema[:required] = required_params unless required_params.empty?
            end

            schema
          end

          def build_basic_schema(object_type, object_format)
            schema = { type: object_type }
            schema[:format] = object_format if object_format
            if param_options[:default] && serializable?(param_options[:default])
              schema[:default] = param_options[:default]
            end

            schema[:description] = annotated_description if param_options[:desc]

            if param_options.dig(:documentation, :example)
              schema[:example] = param_options.dig(:documentation, :example)
            end

            # Add regex validations
            validation = validations&.find do |v|
              v[:validator_class] == Grape::Validations::Validators::RegexpValidator
            end

            if validation
              pattern = regexp_to_pattern(validation[:options])
              schema[:pattern] = pattern if pattern
            end

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

          def apply_allow_blank(schema)
            if param_options[:allow_blank] == false || (param_options[:required] && param_options[:values])
              schema[:minLength] = 1 if schema[:type] == 'string'
            elsif schema[:oneOf]
              schema[:oneOf].each { |s| s[:nullable] = true }
            else
              schema[:nullable] = true
            end
          end
        end
      end
    end
  end
end
