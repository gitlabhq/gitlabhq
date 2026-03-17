# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Models
      class Parameter
        # https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.0.md#parameter-object
        attr_reader :name, :required, :in_value, :description, :options, :schema, :example
        attr_accessor :style, :explode

        def initialize(name, options:, schema:, in_value:)
          @options = options
          @name = name
          # From https://spec.openapis.org/oas/v3.2.0.html#common-fixed-fields: "If the parameter
          # location is 'path', this property is REQUIRED and its value MUST be true.
          @required = in_value == 'path' ? true : options[:required]
          @description = options[:desc]
          @schema = schema
          @in_value = in_value
          @example = options.dig(:documentation, :example)
          @default = options.dig(:documentation, :default)
          @style = nil
          @explode = nil
        end

        def to_h
          result = {
            name: name,
            required: required,
            description: description,
            schema: schema,
            in: in_value,
            example: example
          }

          result[:style] = style if style
          result[:explode] = explode unless explode.nil?
          result.compact
        end
      end
    end
  end
end
