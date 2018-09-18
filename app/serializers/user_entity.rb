# frozen_string_literal: true

class UserEntity < API::Entities::UserBasic
  include RequestAwareEntity
  include UserStatusTooltip

  expose :user_preference, using: UserPreferenceEntity

  expose :path do |user|
    user_path(user)
  end
end
