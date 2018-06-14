module ProtectedRefAccess
  extend ActiveSupport::Concern

  ALLOWED_ACCESS_LEVELS = [
    Gitlab::Access::MAINTAINER,
    Gitlab::Access::DEVELOPER,
    Gitlab::Access::NO_ACCESS,
    Gitlab::Access::ADMIN
  ].freeze

  HUMAN_ACCESS_LEVELS = {
    Gitlab::Access::MAINTAINER => "Maintainers".freeze,
    Gitlab::Access::DEVELOPER => "Developers + Maintainers".freeze,
    Gitlab::Access::NO_ACCESS => "No one".freeze
  }.freeze

  included do
    scope :master, -> { maintainer } # @deprecated
    scope :maintainer, -> { where(access_level: Gitlab::Access::MAINTAINER) }
    scope :developer, -> { where(access_level: Gitlab::Access::DEVELOPER) }
    scope :by_user, -> (user) { where(user_id: user ) }
    scope :by_group, -> (group) { where(group_id: group ) }
    scope :for_role, -> { where(user_id: nil, group_id: nil) }
    scope :for_user, -> { where.not(user_id: nil) }
    scope :for_group, -> { where.not(group_id: nil) }

    validates :access_level, presence: true, if: :role?, inclusion: {
      in: ALLOWED_ACCESS_LEVELS
    }
  end

  def humanize
    HUMAN_ACCESS_LEVELS[self.access_level]
  end

  # CE access levels are always role-based,
  # where as EE allows groups and users too
  def role?
    true
  end

  def check_access(user)
    return true if user.admin?

    user.can?(:push_code, project) &&
      project.team.max_member_access(user.id) >= access_level
  end
end
