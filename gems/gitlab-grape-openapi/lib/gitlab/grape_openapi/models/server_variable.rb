# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Models
      # https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.0.md#server-variable-object
      class ServerVariable
        attr_reader :default, :description, :enum

        def initialize(default:, description: nil, enum: nil)
          @default = default
          @description = description
          @enum = enum
        end

        def to_h
          hash = { default: default }
          hash[:description] = description if description.present?
          hash[:enum] = enum if enum.present?
          hash
        end
      end
    end
  end
end
