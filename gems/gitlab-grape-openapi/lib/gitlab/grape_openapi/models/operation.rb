# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Models
      class Operation
        # https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.0.md#operation-object
        attr_accessor :operation_id, :description, :tags, :responses, :parameters, :request_body, :summary

        def initialize
          @tags = []
          @request_body = {}
          @parameters = []
        end

        def to_h
          @parameters ||= []

          o = {
            operationId: operation_id,
            summary: summary,
            description: description,
            tags: tags && tags.empty? ? nil : tags,
            responses: responses
          }.compact

          o[:parameters] = parameters.map(&:to_h) if parameters.any?
          o[:requestBody] = request_body if request_body.keys.any?

          o
        end
      end
    end
  end
end
