# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Models
      class PathItem
        # https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.0.md#path-item-object
        attr_reader :operations

        def initialize
          @operations = {}
        end

        def add_operation(method, operation)
          @operations[method.to_s.downcase] = operation
        end

        def to_h
          operations.transform_values(&:to_h)
        end
      end
    end
  end
end
