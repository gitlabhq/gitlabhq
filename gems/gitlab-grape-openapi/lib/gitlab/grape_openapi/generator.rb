# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    class Generator
      attr_reader :tag_registry

      def initialize(api_classes, options = {})
        @api_classes = api_classes
        @options = options
        @schema_registry = SchemaRegistry.new
        @tag_registry = TagRegistry.new
      end

      def generate
        initialize_tags

        # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/572530
        {
          openapi: '3.0.0',
          info: Gitlab::GrapeOpenapi.configuration.info.to_h,
          tags: tag_registry.tags,
          servers: Gitlab::GrapeOpenapi.configuration.servers.map(&:to_h),

          paths: paths,
          components: {
            securitySchemes: security_schemes
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
        Converters::PathConverter.convert(all_routes)
      end
    end
  end
end
