# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    class SchemaRegistry
      attr_reader :schemas

      def initialize
        @schemas = {}
      end

      def register(entity_class, schema)
        normalized_name = normalize_entity_class(entity_class)
        return normalized_name if @schemas.key?(normalized_name)

        @schemas[normalized_name] = schema if schema.is_a?(::Gitlab::GrapeOpenapi::Models::Schema)

        normalized_name
      end

      def normalize_entity_class(entity_class)
        entity_class.name.delete(':')
      end
    end
  end
end
