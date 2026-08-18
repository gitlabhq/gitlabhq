# frozen_string_literal: true

module API
  module Entities
    module Glql
      class Field < Grape::Entity
        expose :key, documentation: { type: 'String', example: 'title', desc: 'Unique field key' }
        expose :label, documentation: { type: 'String', example: 'Title', desc: 'Human-readable field label' }
        expose :name, documentation: {
          type: 'String',
          example: 'title',
          desc: 'Underlying name of field, often the same as `key`, but it may be different if one ' \
            'type of field has multiple possible keys. Example `created` and `createdAt`'
        }
        expose :field, documentation: {
          type: 'String',
          example: 'title',
          desc: 'Base field name. For aliased parameterised fields this is the underlying field ' \
            '(for example, `durationQuantile`), while `key` is the alias (for example, `p50`). ' \
            'For standard fields, same as `key`'
        }
        expose :type, expose_nil: false, documentation: {
          type: 'String',
          example: 'dimension',
          desc: 'Field classification. Either `dimension` or `metric` for analytics mode fields, ' \
            'absent for standard fields'
        }
        expose :parameters, expose_nil: false, documentation: {
          type: 'Hash',
          example: { granularity: 'weekly' },
          desc: 'Resolved parameter metadata for parameterised fields, absent when the field has no parameters'
        }
      end
    end
  end
end
