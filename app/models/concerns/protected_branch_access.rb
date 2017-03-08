module ProtectedBranchAccess
  extend ActiveSupport::Concern

  included do
    include EE::ProtectedBranchAccess

    belongs_to :protected_branch
    delegate :project, to: :protected_branch

    scope :master, -> { where(access_level: Gitlab::Access::MASTER) }
    scope :developer, -> { where(access_level: Gitlab::Access::DEVELOPER) }
  end

  def humanize
    self.class.human_access_levels[self.access_level]
  end

  def check_access(user)
    return true if user.is_admin?

    project.team.max_member_access(user.id) >= access_level
  end
end
