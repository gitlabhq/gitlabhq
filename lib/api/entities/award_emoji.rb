# frozen_string_literal: true

module API
  module Entities
    class AwardEmoji < Grape::Entity
      expose :id
      expose :name
      expose :user, using: Entities::UserBasic
      expose :created_at, :updated_at
      expose :awardable_id, :awardable_type
      expose :url
    end
  end
end
