# frozen_string_literal: true
class ProtectedEnvironment::DeployAccessLevel < ActiveRecord::Base
  ALLOWED_ACCESS_LEVELS = [
    Gitlab::Access::MAINTAINER,
    Gitlab::Access::DEVELOPER,
    Gitlab::Access::ADMIN
  ].freeze

  HUMAN_ACCESS_LEVELS = {
    Gitlab::Access::MAINTAINER => 'Maintainers'.freeze,
    Gitlab::Access::DEVELOPER => 'Developers + Maintainers'.freeze
  }.freeze

  belongs_to :user
  belongs_to :group
  belongs_to :protected_environment

  validates :access_level, presence: true, if: :role?, inclusion: {
    in: ALLOWED_ACCESS_LEVELS
  }

  delegate :project, to: :protected_environment

  def check_access(user)
    return true if user.admin?
    return user.id == user_id if user_type?
    return group.users.exists?(user.id) if group_type?

    project.team.max_member_access(user.id) >= access_level
  end

  def user_type?
    user_id.present?
  end

  def group_type?
    group_id.present?
  end

  def type
    if user_type?
      :user
    elsif group_type?
      :group
    else
      :role
    end
  end

  def role?
    type == :role
  end

  def humanize
    return user.name if user_type?
    return group.name if group_type?

    HUMAN_ACCESS_LEVELS[access_level]
  end
end
