# frozen_string_literal: true

module API
  module Entities
    class MergeRequestReviewer < Grape::Entity
      expose :reviewer, as: :user, using: ::API::Entities::UserBasic
      expose :state, documentation: { type: 'String', example: 'unreviewed' }
      expose :created_at, documentation: { type: 'DateTime', example: '2022-01-31T15:10:45.080Z' }
    end
  end
end
