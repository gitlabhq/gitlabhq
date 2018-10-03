# frozen_string_literal: true

# Always use this entity when rendering data for current user
# for attributes that does not need to be visible to other users
# like user preferences.
class CurrentUserEntity < UserEntity
  expose :user_preference, using: UserPreferenceEntity
end
