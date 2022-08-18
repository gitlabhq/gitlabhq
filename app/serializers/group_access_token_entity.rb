# frozen_string_literal: true

# rubocop: disable Gitlab/NamespacedClass
class GroupAccessTokenEntity < API::Entities::PersonalAccessToken
  include Gitlab::Routing

  expose :revoke_path do |token, options|
    group = options.fetch(:group)

    next unless group

    revoke_group_settings_access_token_path(
      id: token,
      group_id: group.path)
  end

  expose :access_level do |token, options|
    group = options.fetch(:group)

    next unless group
    next unless token.user

    group.member(token.user)&.access_level
  end
end
# rubocop: enable Gitlab/NamespacedClass
