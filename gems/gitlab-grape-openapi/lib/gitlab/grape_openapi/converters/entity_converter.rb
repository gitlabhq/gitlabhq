# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Converters
      class EntityConverter
        attr_reader :entity_class, :schema_registry

        OBJECT_TYPE = 'object'
        ARRAY_TYPE = 'array'
        DEFAULT_TYPE = 'string'
        REF_KEY = '$ref'
        SCHEMA_PATH_PREFIX = '#/components/schemas/'

        def self.register(entity, schema_registry)
          case entity
          when Class
            return unless grape_entity?(entity)

            new(entity, schema_registry).convert
          when Hash
            return unless entity[:model] && grape_entity?(entity[:model])

            new(entity[:model], schema_registry).convert
          when Array
            entity.each do |definition|
              next unless definition.is_a?(Hash) && definition[:model] && grape_entity?(definition[:model])

              new(definition[:model], schema_registry).convert
            end
          end
        end

        def self.grape_entity?(klass)
          klass.is_a?(Class) && klass.ancestors.include?(Grape::Entity)
        end

        def initialize(entity_class, schema_registry)
          @entity_class = entity_class
          @schema_registry = schema_registry
        end

        def convert
          normalized_name = schema_registry.normalize_entity_class(entity_class)
          return schema_registry.schemas[normalized_name] if schema_registry.schemas.key?(normalized_name)

          schema = build_schema
          schema_registry.register(entity_class, schema)
          schema
        end

        private

        def build_schema
          Models::Schema.new.tap do |schema|
            schema.type = OBJECT_TYPE
            schema.properties = build_properties
          end
        end

        def build_properties
          root_exposures.each_with_object({}) do |exposure, properties|
            # rubocop:disable GitlabSecurity/PublicSend - Forced to use private API
            attribute = exposure.send(:options)[:as] || exposure.attribute
            # rubocop:enable GitlabSecurity/PublicSend
            properties[attribute] = build_property(exposure)
          end
        end

        def build_property(exposure)
          property = extract_basic_attributes(exposure)
          apply_type_specific_attributes!(property, exposure)
          property.compact
        end

        def extract_basic_attributes(exposure)
          documentation = exposure_documentation(exposure)
          options = exposure_options(exposure)

          type = documentation[:type]

          if multiple_types?(type)
            build_one_of_property(type, documentation, options)
          else
            build_single_type_property(type, documentation, options)
          end
        end

        def multiple_types?(type)
          type.is_a?(Array) && type.length > 1
        end

        def build_one_of_property(types, documentation, options)
          {
            oneOf: types.map { |type| build_type_schema(type, documentation) },
            description: documentation[:desc],
            default: options[:default],
            example: documentation[:example]
          }
        end

        def build_single_type_property(type, documentation, options)
          # Handle single element arrays
          actual_type = type.is_a?(Array) ? type.first : type

          {
            type: TypeResolver.resolve_type(actual_type) || DEFAULT_TYPE,
            description: documentation[:desc],
            format: TypeResolver.resolve_format(documentation[:format], actual_type),
            default: options[:default],
            example: documentation[:example]
          }
        end

        def build_type_schema(type, documentation)
          schema = { type: TypeResolver.resolve_type(type) || DEFAULT_TYPE }

          format = TypeResolver.resolve_format(documentation[:format], type)
          schema[:format] = format if format

          schema
        end

        def apply_type_specific_attributes!(property, exposure)
          # Skip type-specific handling for oneOf properties
          return if property[:oneOf]

          if array_exposure?(exposure)
            handle_array_property!(property, exposure)
          elsif nested_entity?(exposure)
            handle_entity_reference!(property, exposure)
          end
        end

        def handle_array_property!(property, exposure)
          if nested_entity?(exposure)
            reference = build_reference(exposure)
            set_array_property!(property, reference)
          else
            set_array_primitive_property!(property)
          end
        end

        def handle_entity_reference!(property, exposure)
          reference = build_reference(exposure)
          set_reference_property!(property, reference)
        end

        def set_array_primitive_property!(property)
          item_type = property[:type] || DEFAULT_TYPE
          property[:type] = ARRAY_TYPE
          property[:items] = build_primitive_items(property, item_type)
        end

        def build_primitive_items(property, item_type)
          items = { type: item_type }

          # Move format to items if present
          if property[:format]
            items[:format] = property[:format]
            property[:format] = nil
          end

          items
        end

        def set_array_property!(property, reference)
          property[:type] = ARRAY_TYPE
          property[:items] = { REF_KEY => reference }
        end

        def set_reference_property!(property, reference)
          property[:type] = nil
          property[REF_KEY] = reference
        end

        def build_reference(exposure)
          entity_name = nested_entity_class(exposure)
          "#{SCHEMA_PATH_PREFIX}#{normalize_entity_name(entity_name)}"
        end

        def normalize_entity_name(entity_name)
          if entity_name.is_a?(Class)
            entity_name.name.delete(':')
          else
            entity_name.delete(':')
          end
        end

        def root_exposures
          entity_class.root_exposure.nested_exposures
        end

        def exposure_documentation(exposure)
          exposure.documentation || {}
        end

        def exposure_options(exposure)
          exposure.send(:options) || {} # rubocop:disable GitlabSecurity/PublicSend - Forced to use private API
        end

        def nested_entity?(exposure)
          !nested_entity_class(exposure).nil?
        end

        def nested_entity_class(exposure)
          exposure_options(exposure)[:using]
        end

        def array_exposure?(exposure)
          exposure_documentation(exposure)[:is_array]
        end
      end
    end
  end
end
