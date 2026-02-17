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
      end
    end
  end
end
