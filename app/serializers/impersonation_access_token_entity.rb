# frozen_string_literal: true

# rubocop: disable Gitlab/NamespacedClass
class ImpersonationAccessTokenEntity < AccessTokenEntityBase
  include Gitlab::Routing

  expose :revoke_path do |token, _options|
    revoke_admin_user_impersonation_token_path(token.user, token)
  end

  expose :rotate_path do |token, _options|
    rotate_admin_user_impersonation_token_path(token.user, token)
  end
end
# rubocop: enable Gitlab/NamespacedClass
