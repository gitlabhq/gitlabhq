# frozen_string_literal: true

class AwardEmojiEntity < Grape::Entity
  expose :name
  expose :user, using: API::Entities::UserSafe
end
