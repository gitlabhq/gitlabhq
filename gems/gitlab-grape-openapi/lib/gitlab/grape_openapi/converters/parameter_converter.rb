# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Converters
      class ParameterConverter
        attr_reader :name, :options, :validations, :route_path

        def self.convert(name, options:, route_path:, validations: [])
          new(name, options: options, validations: validations, route_path: route_path).convert
        end

        def initialize(name, options:, validations:, route_path:)
          @name = name
          @options = options
          @validations = validations
          @route_path = route_path # Useful for detecting `in` value.
        end

        def in_value
          route_path.include?("/:#{name}") ? 'path' : 'query'
        end

        def example
          @options.dig(:documentation, :example)
        end

        def schema
          object_type = resolve_object_type
          object_format = resolve_object_format

          return build_union_schema(object_type) if options[:type]&.start_with?('[')
          return build_enum_schema(object_type) if options[:values]
          return build_array_schema if array_type?(object_type)

          build_basic_schema(object_type, object_format)
        end

        def resolve_object_format
          'date-time' if options[:type] == 'DateTime'
        end

        def resolve_object_type
          return 'string' if options[:type] == 'DateTime'

          TypeResolver.resolve_type(options[:type]) || 'string'
        end

        def build_union_schema(object_type)
          types = object_type[1..-2].split(", ")
          { oneOf: types.map { |type| { type: TypeResolver.resolve_type(type) } } }
        end

        def build_enum_schema(object_type)
          { type: object_type, enum: options[:values] }
        end

        def build_array_schema
          item_type = extract_array_item_type
          { type: 'array', items: { type: item_type } }
        end

        def build_basic_schema(object_type, object_format)
          schema = { type: object_type }
          schema[:format] = object_format if object_format
          schema[:default] = options[:default] if options[:default]
          add_regex_validations!(schema)
          schema
        end

        def array_type?(object_type)
          object_type.include?('[')
        end

        def extract_array_item_type
          options[:type].delete('[').delete(']').downcase
        end

        def add_regex_validations!(schema)
          # Only support one Regex validation per attribute
          validation = validations.find { |v| v[:validator_class] == Grape::Validations::Validators::RegexpValidator }
          return unless validation

          schema[:pattern] = validation[:options].inspect.delete("/")
        end

        def convert
          Gitlab::GrapeOpenapi::Models::Parameter.new(name, options: options, schema: schema, in_value: in_value,
            example: example)
        end
      end
    end
  end
end
