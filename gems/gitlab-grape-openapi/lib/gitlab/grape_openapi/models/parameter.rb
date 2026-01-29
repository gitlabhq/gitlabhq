# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Models
      class Parameter
        # https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.0.md#parameter-object
        attr_reader :name, :required, :in_value, :description, :options, :schema, :example, :default

        def initialize(name, options:, schema:, in_value:)
          @options = options
          @name = name
          @required = options[:required]
          @description = options[:desc]
          @schema = schema
          @in_value = in_value
          @example = options.dig(:documentation, :example)
          @default = options.dig(:documentation, :default)
        end

        def to_h
          {
            name: name,
            required: required,
            description: description,
            schema: schema,
            in: in_value,
            example: example,
            default: default
          }.compact
        end
      end
    end
  end
end
