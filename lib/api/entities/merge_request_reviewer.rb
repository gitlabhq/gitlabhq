# frozen_string_literal: true

module API
  module Entities
    class MergeRequestReviewer < Grape::Entity
      expose :reviewer, as: :user, using: Entities::UserBasic
      expose :state
      expose :created_at
    end
  end
end
