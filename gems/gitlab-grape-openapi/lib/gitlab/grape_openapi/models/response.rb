# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Models
      # https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.0.md#response-object
      class Response
        attr_reader :status_code, :description, :entity_class, :headers, :content_type

        def initialize(status_code:, description:, entity_class:, headers: {}, content_type: 'application/json')
          @status_code = status_code.to_s
          @description = description
          @entity_class = entity_class
          @headers = headers
          @content_type = content_type
        end

        def to_h(schema_registry)
          response = {
            description: description,
            content: {
              content_type => {
                schema: { '$ref': schema_ref(schema_registry) }
              }
            }
          }

          response[:headers] = headers if headers.any?

          response
        end

        private

        def schema_ref(schema_registry)
          normalized_name = schema_registry.register(entity_class, nil)
          "#/components/schemas/#{normalized_name}"
        end
      end
    end
  end
end
