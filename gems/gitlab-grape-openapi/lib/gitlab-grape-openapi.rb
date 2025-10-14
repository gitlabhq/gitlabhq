# frozen_string_literal: true

require_relative "gitlab/grape_openapi/version"
require_relative "gitlab/grape_openapi/configuration"
require_relative "gitlab/grape_openapi/generator"
require_relative "gitlab/grape_openapi/schema_registry"

# Converters
require_relative "gitlab/grape_openapi/converters/entity_converter"
require_relative "gitlab/grape_openapi/converters/type_resolver"

# Models
require_relative "gitlab/grape_openapi/models/schema"

module Gitlab
  module GrapeOpenapi
    class << self
      attr_writer :configuration

      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration)
      end

      def generate(api_classes, options = {})
        Generator.new(api_classes, options).generate
      end
    end
  end
end
