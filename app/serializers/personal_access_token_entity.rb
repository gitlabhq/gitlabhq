# frozen_string_literal: true

# rubocop: disable Gitlab/NamespacedClass
class PersonalAccessTokenEntity < AccessTokenEntityBase
  include Gitlab::Routing

  expose :revoke_path do |token, options|
    revoke_profile_personal_access_token_path(token)
  end
end
# rubocop: enable Gitlab/NamespacedClass
