class AwardEmojiEntity < Grape::Entity
  expose :name
  expose :user, using: API::Entities::UserSafe
end
