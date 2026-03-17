# frozen_string_literal: true

module Gitlab
  module GrapeOpenapi
    module Converters
      class TypeResolver
        TYPE_MAPPINGS = {
          'API::Validations::Types::WorkhorseFile' => 'string',
          'Array' => 'array',
          'BigDecimal' => 'number',
          'Boolean' => 'boolean',
          'date' => 'string',
          'Date' => 'string',
          'date-time' => 'string',
          'dateTime' => 'string',
          'DateTime' => 'string',
          'FalseClass' => 'boolean',
          'Grape::API::Boolean' => 'boolean',
          'Gitlab::Color' => 'string',
          :int => 'integer',
          'int' => 'integer',
          Integer => 'integer',
          'Integer' => 'integer',
          'File' => 'string',
          Float => 'number',
          'Float' => 'number',
          :hash => 'object',
          'hash' => 'object',
          'Hash' => 'object',
          'JSON' => 'object',
          'Numeric' => 'number',
          String => 'string',
          'String' => 'string',
          'symbol' => 'string',
          'Symbol' => 'string',
          'text' => 'string',
          'Time' => 'string',
          'TrueClass' => 'boolean'
        }.freeze

        FORMAT_MAPPINGS = {
          'API::Validations::Types::WorkhorseFile' => 'binary',
          'date' => 'date',
          'Date' => 'date',
          'date-time' => 'date-time',
          'dateTime' => 'date-time',
          'DateTime' => 'date-time',
          'File' => 'binary',
          'Time' => 'date-time'
        }.freeze

        def self.resolve_type(type)
          return TYPE_MAPPINGS[type] if TYPE_MAPPINGS[type]
          return type unless type.is_a?(String)
          return 'object' if type.start_with?('API::')

          type
        end

        def self.resolve_format(format, type)
          format || FORMAT_MAPPINGS[type]
        end

        def self.resolve_union_member(type)
          if type.start_with?('[') && type.end_with?(']')
            item_type = type[1..-2]
            { type: 'array', items: { type: resolve_type(item_type) || 'string' } }
          else
            { type: resolve_type(type) || 'string' }
          end
        end
      end
    end
  end
end
