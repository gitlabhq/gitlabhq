# frozen_string_literal: true

# rubocop: disable Gitlab/NamespacedClass
class GroupAccessTokenEntity < AccessTokenEntityBase
  include Gitlab::Routing

  expose :revoke_path do |token, options|
    group = options.fetch(:group)

    next unless group

    revoke_group_settings_access_token_path(
      id: token,
      group_id: group.full_path)
  end

  expose :rotate_path do |token, options|
    group = options.fetch(:group)

    next unless group

    rotate_group_settings_access_token_path(
      id: token,
      group_id: group.full_path)
  end

  expose :role do |token, options|
    group = options.fetch(:group)

    next unless group
    next unless token.user

    group.member(token.user)&.human_access
  end
end
# rubocop: enable Gitlab/NamespacedClass
