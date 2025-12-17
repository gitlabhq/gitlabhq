# frozen_string_literal: true

module API
  module Entities
    class AwardEmoji < Grape::Entity
      expose :id, documentation: { type: 'Integer', example: 1 }
      expose :name, documentation: { type: 'String', example: 'lizard' }
      expose :user, using: Entities::UserBasic
      expose :created_at, documentation: { type: 'DateTime', example: '2019-01-10T13:39:08Z' }
      expose :updated_at, documentation: { type: 'DateTime', example: '2020-06-28T10:52:04Z' }
      expose :awardable_id, documentation: { type: 'Integer', example: 42 }
      expose :awardable_type, documentation: { type: 'String', example: 'Issue' }
      expose :url, documentation: { type: 'String', example: 'https://example.com/emojis/example.gif' }
    end
  end
end
