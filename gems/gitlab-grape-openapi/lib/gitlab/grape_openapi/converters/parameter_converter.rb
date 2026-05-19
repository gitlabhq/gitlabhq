# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Converters
      class ParameterConverter
        include CoercerResolver
        include Concerns::Serializable
        include Concerns::LimitResolver
        include Concerns::FailFastAnnotatable
        include Concerns::RegexConverter

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
          # Strip only the :version path segment (not substrings like :version_id or :package_version),
          # then match the param name as a complete segment bounded by / . ( or end-of-string.
          route.path.gsub('/:version/', '/').match?(%r{/:#{Regexp.escape(name)}([/.(]|$)}) ? 'path' : 'query'
        end

        def example
          @options.dig(:documentation, :example)
        end

        def coercer_mapping
          @coercer_mapping ||= coercer_mapping_for(validations)
        end

        def schema
          object_type = TypeResolver.resolve_type(options[:type]) || 'string'
          object_format = TypeResolver.resolve_format(nil, options[:type])
          type_str = options[:type].to_s

          mapping = coercer_mapping
          built_schema = if mapping
                           build_coerced_schema(mapping)
                         elsif type_str.start_with?('[') && type_str.exclude?(',')
                           build_simple_array_schema
                         elsif type_str.start_with?('[')
                           build_union_schema(object_type)
                         elsif options[:values].is_a?(Range)
                           build_range_schema(object_type)
                         elsif options[:values]
                           build_enum_schema(object_type)
                         elsif array_type?(object_type)
                           build_array_schema
                         else
                           build_basic_schema(object_type, object_format)
                         end

          apply_allow_blank(built_schema)
          apply_limit!(built_schema, validations)
          built_schema
        end

        def build_simple_array_schema
          item_type = options[:type].to_s.delete('[').delete(']')
          { type: 'array', items: { type: TypeResolver.resolve_type(item_type) } }
        end

        def build_union_schema(object_type)
          types = object_type[1..-2].split(", ")
          members = types.map { |type| TypeResolver.resolve_union_member(type) }
          apply_union_enum!(members)
          apply_union_default!(members)
          { oneOf: members }
        end

        def build_range_schema(object_type)
          range = options[:values]
          schema = { type: object_type }

          schema[:minimum] = range.begin if range.begin
          schema[:maximum] = range.end if range.end
          schema[:default] = options[:default] if options[:default] && serializable?(options[:default])
          schema
        end

        def build_enum_schema(object_type)
          schema = { type: object_type }
          schema[:enum] = options[:values] unless options[:values].is_a?(Proc)
          schema[:default] = options[:default] if options[:default] && serializable?(options[:default])
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

          pattern = regexp_to_pattern(validation[:options])
          schema[:pattern] = pattern if pattern
        end

        def convert
          # For requests that can have a request body (POST, PUT, PATCH, etc.), only return a param if it's in the path,
          # otherwise it'll be a body parameter and shouldn't be included as a query parameter.
          # GET and DELETE requests don't have request bodies, so all their parameters are included.
          method = route.instance_variable_get(:@options)[:method]
          return nil if method != 'GET' && method != 'DELETE' && in_value != 'path'

          annotated = options.dup
          if options[:desc] && fail_fast_in_validations?(validations)
            annotated[:desc] = annotate_fail_fast(options[:desc])
          end

          param = Gitlab::GrapeOpenapi::Models::Parameter.new(
            name,
            options: annotated,
            schema: schema,
            in_value: in_value
          )

          mapping = coercer_mapping
          return param unless mapping

          param.style = mapping[:style] if mapping[:style]
          param.explode = mapping[:explode] if mapping.key?(:explode)
          param
        end

        private

        def time_serializer
          @time_serializer ||= Serializers::Time.new
        end

        # When a union (oneOf) schema has a `values:` constraint, propagate it
        # as `enum` onto each oneOf member whose type can carry the values.
        # Skip Procs/Ranges to mirror build_enum_schema behavior.
        def apply_union_enum!(members)
          values = options[:values]
          return if values.nil? || values.is_a?(Proc) || values.is_a?(Range)

          members.each do |member|
            case member[:type]
            when 'integer'
              ints = values.select { |v| v.is_a?(Integer) }
              member[:enum] = ints if ints.any?
            when 'number'
              nums = values.select { |v| v.is_a?(Numeric) }
              member[:enum] = nums if nums.any?
            when 'string'
              member[:enum] = values.map(&:to_s)
            end
          end
        end

        # When a union (oneOf) schema has a `default:`, attach it to every member
        # whose schema can accept the default value. For arrays this includes
        # checking the items type so `[1, 2]` lands on `items: { type: integer }`
        # but not on `items: { type: string }`. Empty arrays are type-agnostic
        # and attach to all array members.
        def apply_union_default!(members)
          default = options[:default]
          return unless default && serializable?(default)

          members.each do |member|
            member[:default] = default if member_accepts_default?(member, default)
          end
        end

        def member_accepts_default?(member, default)
          case member[:type]
          when 'integer' then default.is_a?(Integer)
          when 'number'  then default.is_a?(Numeric)
          when 'boolean' then [true, false].include?(default)
          when 'string'  then default.is_a?(String) || default.is_a?(Symbol)
          when 'array'   then array_member_accepts?(member, default)
          when 'object'  then default.is_a?(Hash)
          end
        end

        def array_member_accepts?(member, default)
          return false unless default.is_a?(Array)
          return true if default.empty?

          item_type = member.dig(:items, :type)
          default.all? { |element| openapi_type_accepts?(item_type, element) }
        end

        def openapi_type_accepts?(openapi_type, value)
          case openapi_type
          when 'integer' then value.is_a?(Integer)
          when 'number'  then value.is_a?(Numeric)
          when 'boolean' then [true, false].include?(value)
          when 'string'  then value.is_a?(String) || value.is_a?(Symbol)
          else true
          end
        end

        # allow_blank defaults to true
        # when `allow_blank: false` for a string type minLength should be set to 1
        # when param is required and values option used, the param is not nullable
        def apply_allow_blank(schema)
          if options[:allow_blank] == false || (options[:required] && options[:values])
            schema[:minLength] = 1 if schema[:type] == 'string'
          elsif in_value != 'path'
            # path parameters are never nullable because they are required URL segments
            if schema[:oneOf]
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
