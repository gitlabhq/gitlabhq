# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Models
      # https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.0.md#schema-object
      class Schema
        attr_accessor :properties, :type

        def initialize
          @properties = {}
        end

        def method_missing(method_name, *_args)
          raise NoMethodError unless respond_to_missing?(method_name)

          properties[method_name]
        end

        def respond_to_missing?(method_name, _include_private = false)
          properties.key?(method_name)
        end

        def to_h
          build_schema_hash
        end

        private

        def build_schema_hash
          {}.tap do |hash|
            add_type_and_format(hash)
            add_properties(hash)
          end
        end

        def add_type_and_format(hash)
          hash[:type] = type if type
          hash[:format] = @properties[:format] if @properties[:format]
        end

        def add_properties(hash)
          return if properties.empty?

          hash[:properties] = properties.transform_values(&:to_h)
        end

        def description
          @properties[:description]
        end

        def default
          @properties[:default]
        end

        def example
          @properties[:example]
        end
      end
    end
  end
end
