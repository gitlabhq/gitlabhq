# frozen_string_literal: true

module API
  module Entities
    class BasicReleaseDetails < Grape::Entity
      include ::API::Helpers::Presentable

      expose :name, documentation: { type: 'string', example: 'Release v1.0' }
      expose :tag, documentation: { type: 'string', example: 'v1.0' }, as: :tag_name
      expose :description, documentation: { type: 'string', example: 'Finally released v1.0' }
      expose :created_at, documentation: { type: 'dateTime', example: '2019-01-03T01:56:19.539Z' }
      expose :released_at, documentation: { type: 'dateTime', example: '2019-01-03T01:56:19.539Z' }
      expose :upcoming_release?, documentation: { type: 'boolean' }, as: :upcoming_release
    end
  end
end
