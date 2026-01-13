# frozen_string_literal: true

module API
  module Entities
    class BasicReleaseDetails < Grape::Entity
      include ::API::Helpers::Presentable

      expose :name, documentation: { type: 'String', example: 'Release v1.0' }
      expose :tag, documentation: { type: 'String', example: 'v1.0' }, as: :tag_name
      expose :description, documentation: { type: 'String', example: 'Finally released v1.0' }
      expose :created_at, documentation: { type: 'DateTime', example: '2019-01-03T01:56:19.539Z' }
      expose :released_at, documentation: { type: 'DateTime', example: '2019-01-03T01:56:19.539Z' }
      expose :upcoming_release?, documentation: { type: 'Boolean' }, as: :upcoming_release
    end
  end
end
