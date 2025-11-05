# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Converters
      class TypeResolver
        TYPE_MAPPINGS = {
          'dateTime' => 'string',
          'date' => 'string',
          'symbol' => 'string',
          'String' => 'string',
          String => 'string',
          'Integer' => 'integer',
          Integer => 'integer',
          :int => 'integer',
          'text' => 'string',
          'Hash' => 'object',
          'hash' => 'object',
          'JSON' => 'object',
          :hash => 'object',
          'Grape::API::Boolean' => 'boolean'
        }.freeze

        FORMAT_MAPPINGS = {
          'dateTime' => 'date-time',
          'date' => 'date'
        }.freeze

        def self.resolve_type(type)
          TYPE_MAPPINGS[type] || type
        end

        def self.resolve_format(format, type)
          format || FORMAT_MAPPINGS[type]
        end
      end
    end
  end
end
