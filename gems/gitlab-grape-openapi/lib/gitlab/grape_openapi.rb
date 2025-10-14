# frozen_string_literal: true

require_relative "grape_openapi/version"
require_relative "grape_openapi/configuration"
require_relative "grape_openapi/generator"

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
