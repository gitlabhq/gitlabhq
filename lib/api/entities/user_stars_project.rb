# frozen_string_literal: true

module API
  module Entities
    class UserStarsProject < Grape::Entity
      expose :starred_since
      expose :user, using: Entities::UserBasic
    end
  end
end
