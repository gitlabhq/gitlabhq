# frozen_string_literal: true

# rubocop: disable Gitlab/NamespacedClass
class PersonalAccessTokenEntity < AccessTokenEntityBase
  include Gitlab::Routing

  expose :revoke_path do |token, options|
    revoke_user_settings_personal_access_token_path(token)
  end

  expose :rotate_path do |token, options|
    rotate_user_settings_personal_access_token_path(token)
  end
end
# rubocop: enable Gitlab/NamespacedClass
