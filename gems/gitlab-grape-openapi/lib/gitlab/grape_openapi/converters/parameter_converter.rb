# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Converters
      class ParameterConverter
        attr_reader :name, :options, :validations, :route

        def self.convert(name, options:, route:, validations: [])
          new(name, options: options, validations: validations, route: route).convert
        end

        def initialize(name, options:, validations:, route:)
          @name = name
          @options = options
          @validations = validations
          @route = route # Useful for detecting `in` value.
        end

        def in_value
          route.path.gsub('version', '').include?("/:#{name}") ? 'path' : 'query'
        end

        def example
          @options.dig(:documentation, :example)
        end

        def schema
          object_type = resolve_object_type
          object_format = resolve_object_format

          return build_union_schema(object_type) if options[:type]&.start_with?('[')
          return build_range_schema(object_type) if options[:values].is_a?(Range)
          return build_enum_schema(object_type) if options[:values]
          return build_array_schema if array_type?(object_type)

          build_basic_schema(object_type, object_format)
        end

        def resolve_object_format
          return 'date-time' if options[:type] == 'DateTime'

          'date' if options[:type] == 'Date'
        end

        def resolve_object_type
          return 'string' if options[:type] == 'DateTime' || options[:type] == 'Date'

          TypeResolver.resolve_type(options[:type]) || 'string'
        end

        def build_union_schema(object_type)
          types = object_type[1..-2].split(", ")
          { oneOf: types.map { |type| { type: TypeResolver.resolve_type(type) } } }
        end

        def build_range_schema(object_type)
          range = options[:values]
          schema = { type: object_type }

          schema[:minimum] = range.begin if range.begin
          schema[:maximum] = range.end if range.end

          schema
        end

        def build_enum_schema(object_type)
          schema = { type: object_type }
          schema[:enum] = options[:values] unless options[:values].is_a?(Proc)
          schema
        end

        def build_array_schema
          item_type = extract_array_item_type
          { type: 'array', items: { type: item_type } }
        end

        def build_basic_schema(object_type, object_format)
          schema = { type: object_type }
          schema[:format] = object_format if object_format
          if options[:default] && serializable?(options[:default])
            schema[:default] = options[:default]
          elsif options[:default] &&
              defined?(ActiveSupport::TimeWithZone) &&
              options[:default].is_a?(ActiveSupport::TimeWithZone)
            serialized_default = time_serializer.serialize(options[:default], example: example)
            schema[:default] = serialized_default if serialized_default
          end

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
          return unless validations

          # Only support one Regex validation per attribute
          validation = validations&.find { |v| v[:validator_class] == Grape::Validations::Validators::RegexpValidator }
          return unless validation

          schema[:pattern] = validation[:options].inspect.delete("/")
        end

        def convert
          # For requests that can have a request body (POST, PUT, PATCH, etc.), only return a param if it's in the path,
          # otherwise it'll be a body parameter and shouldn't be included as a query parameter.
          # GET and DELETE requests don't have request bodies, so all their parameters are included.
          method = route.instance_variable_get(:@options)[:method]
          return nil if method != 'GET' && method != 'DELETE' && in_value != 'path'

          Gitlab::GrapeOpenapi::Models::Parameter.new(name, options: options, schema: schema, in_value: in_value)
        end

        private

        def serializable?(value)
          # Exclude lambdas/procs (they're evaluated at runtime, not suitable for static specs)
          return false if value.is_a?(Proc)

          # Exclude ActiveSupport::TimeWithZone objects (they serialize poorly to YAML)
          return false if defined?(ActiveSupport::TimeWithZone) && value.is_a?(ActiveSupport::TimeWithZone)

          # Exclude Time objects (they should be strings in OpenAPI)
          return false if value.is_a?(Time)

          true
        end

        def time_serializer
          @time_serializer ||= Serializers::Time.new
        end
      end
    end
  end
end
