# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Models
      class Operation
        # https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.0.md#operation-object
        attr_accessor :operation_id, :description, :tags, :responses, :parameters

        def initialize
          @tags = []
          @parameters = []
        end

        def to_h
          @parameters ||= []

          o = {
            operationId: operation_id,
            description: description,
            tags: tags && tags.empty? ? nil : tags,
            responses: responses
          }.compact

          o[:parameters] = parameters.map(&:to_h) if parameters.any?
          # Need to add bodyParameters here conditionally too - probably in a follow-up.

          o
        end
      end
    end
  end
end
