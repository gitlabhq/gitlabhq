# frozen_string_literal: true

module Mcp
  module Tools
    module Base
      module SchemaDefaults
        COMPOSITION_KEYS = %i[oneOf anyOf allOf $ref].freeze

        def self.with_additional_properties(schema)
          return schema if key?(schema, :additionalProperties)
          return schema if COMPOSITION_KEYS.any? { |k| key?(schema, k) }

          schema.merge(additionalProperties: false)
        end

        def self.key?(schema, name)
          schema.key?(name) || schema.key?(name.to_s)
        end
        private_class_method :key?
      end
    end
  end
end
