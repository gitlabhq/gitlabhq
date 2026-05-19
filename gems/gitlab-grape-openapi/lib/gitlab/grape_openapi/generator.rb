# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    class Generator
      attr_reader :tag_registry

      def initialize(options = {})
        @api_classes = Array(options[:api_classes]).reject do |api_class|
          Gitlab::GrapeOpenapi.configuration.excluded_api_classes.include?(api_class.name)
        end
        @schema_registry = SchemaRegistry.new
        @request_body_registry = RequestBodyRegistry.new
        @tag_registry = TagRegistry.new
      end

      def generate
        initialize_tags

        {
          openapi: '3.0.0',
          info: Gitlab::GrapeOpenapi.configuration.info.to_h,
          tags: tag_registry.tags.sort_by { |t| t.fetch(:name, '') },
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

      def paths
        all_routes = @api_classes.flat_map(&:routes)
        Converters::PathConverter.convert(all_routes, @schema_registry, @request_body_registry)
      end

      private

      def schemas
        entity_schemas = @schema_registry.schemas.transform_values(&:to_h)
        request_body_schemas = @request_body_registry.schemas
        entity_schemas.merge(request_body_schemas)
      end
    end
  end
end
