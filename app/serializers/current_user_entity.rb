class CurrentUserEntity < UserEntity
  expose :user_preference, using: UserPreferenceEntity
end
