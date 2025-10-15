# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    class Generator
      def initialize(api_classes, options = {})
        @api_classes = api_classes
        @options = options
        @schema_registry = SchemaRegistry.new
      end

      def generate
        # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/572530
        {
          servers: Gitlab::GrapeOpenapi.configuration.servers.map(&:to_h),
          components: {
            securitySchemes: security_schemes
          },
          security: security_schemes.keys
        }
      end

      def security_schemes
        Gitlab::GrapeOpenapi.configuration.security_schemes.to_h do |scheme|
          [scheme.type, scheme.to_h]
        end
      end
    end
  end
end
