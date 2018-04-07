module ProtectedRefAccess
  extend ActiveSupport::Concern

  ALLOWED_ACCESS_LEVELS = [
    Gitlab::Access::MASTER,
    Gitlab::Access::DEVELOPER,
    Gitlab::Access::NO_ACCESS,
    Gitlab::Access::ADMIN
  ].freeze

  HUMAN_ACCESS_LEVELS = {
    Gitlab::Access::MASTER => "Masters".freeze,
    Gitlab::Access::DEVELOPER => "Developers + Masters".freeze,
    Gitlab::Access::NO_ACCESS => "No one".freeze
  }.freeze

  included do
    scope :master, -> { where(access_level: Gitlab::Access::MASTER) }
    scope :developer, -> { where(access_level: Gitlab::Access::DEVELOPER) }

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
