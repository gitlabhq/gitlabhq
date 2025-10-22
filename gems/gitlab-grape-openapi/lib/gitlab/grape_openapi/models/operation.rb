# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Models
      class Operation
        # https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.0.md#operation-object
        attr_accessor :operation_id, :description, :tags, :responses

        def initialize
          @tags = []
        end

        def to_h
          {
            operationId: operation_id,
            description: description,
            tags: tags.empty? ? nil : tags,
            responses: responses
          }.compact
        end
      end
    end
  end
end
