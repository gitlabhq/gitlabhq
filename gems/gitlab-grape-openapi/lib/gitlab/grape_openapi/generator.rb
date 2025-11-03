# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    class Generator
      attr_reader :tag_registry

      def initialize(options = {})
        @api_classes = Array(options[:api_classes])
        @entity_classes = Array(options[:entity_classes])
        @schema_registry = SchemaRegistry.new
        @tag_registry = TagRegistry.new
      end

      def generate
        initialize_tags
        register_explicit_entities
        register_entities_from_routes

        {
          openapi: '3.0.0',
          info: Gitlab::GrapeOpenapi.configuration.info.to_h,
          tags: tag_registry.tags,
          servers: Gitlab::GrapeOpenapi.configuration.servers.map(&:to_h),
          paths: paths,
          components: {
            securitySchemes: security_schemes,
            schemas: schemas
          },
          security: security_schemes.keys.map { |s| { s => [] } }
        }
      end

      def security_schemes
        Gitlab::GrapeOpenapi.configuration.security_schemes.to_h do |scheme|
          [scheme.type, scheme.to_h]
        end
      end

      def initialize_tags
        @api_classes.each do |api_class|
          Converters::TagConverter.new(api_class, tag_registry).convert
        end
      end

      def register_explicit_entities
        @entity_classes.each do |entity_class|
          next unless grape_entity?(entity_class)

          Converters::EntityConverter.new(entity_class, @schema_registry).convert
        end
      end

      def register_entities_from_routes
        all_routes = @api_classes.flat_map(&:routes)

        all_routes.each do |route|
          entity = route.options[:entity]
          next unless entity

          register_entity(entity)
        end
      end

      def paths
        all_routes = @api_classes.flat_map(&:routes)
        Converters::PathConverter.convert(all_routes, @schema_registry)
      end

      private

      def register_entity(entity)
        case entity
        when Class
          return unless grape_entity?(entity)

          Converters::EntityConverter.new(entity, @schema_registry).convert
        when Hash
          return unless entity[:model] && grape_entity?(entity[:model])

          Converters::EntityConverter.new(entity[:model], @schema_registry).convert
        when Array
          entity.each do |definition|
            next unless definition.is_a?(Hash) && definition[:model] && grape_entity?(definition[:model])

            Converters::EntityConverter.new(definition[:model], @schema_registry).convert
          end
        end
      end

      def grape_entity?(klass)
        klass.is_a?(Class) && klass.ancestors.include?(Grape::Entity)
      end

      def schemas
        @schema_registry.schemas.transform_values(&:to_h)
      end
    end
  end
end
