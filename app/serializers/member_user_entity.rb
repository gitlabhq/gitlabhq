# frozen_string_literal: true

class MemberUserEntity < UserEntity
  unexpose :path
  unexpose :state
  unexpose :status_tooltip_html

  expose :created_at
  expose :last_activity_on

  expose :avatar_url do |user|
    user.avatar_url(size: Member::AVATAR_SIZE, only_path: false)
  end

  expose :blocked do |user|
    user.blocked?
  end

  expose :is_bot do |user|
    user.bot?
  end

  expose :two_factor_enabled, if: ->(user) { current_user_can_manage_members? || current_user?(user) } do |user|
    user.two_factor_enabled?
  end

  expose :status, if: ->(user) { user.status.present? } do
    expose :emoji do |user|
      user.status.emoji
    end
  end

  private

  def current_user_can_manage_members?
    return false unless options[:source]

    Ability.allowed?(options[:current_user], :"admin_#{options[:source].to_ability_name}_member", options[:source])
  end

  def current_user?(user)
    options[:current_user] == user
  end
end

MemberUserEntity.prepend_mod_with('MemberUserEntity')
