module ProtectedBranchAccess
  extend ActiveSupport::Concern

  included do
    validates_uniqueness_of :group_id, scope: :protected_branch, allow_nil: true
    validates_uniqueness_of :user_id, scope: :protected_branch, allow_nil: true
    validates_uniqueness_of :access_level,
                            scope: :protected_branch,
                            unless: Proc.new { |access_level| access_level.user_id? || access_level.group_id? },
                            conditions: -> { where(user_id: nil, group_id: nil) }
    belongs_to :protected_branch
    delegate :project, to: :protected_branch

    scope :master, -> { where(access_level: Gitlab::Access::MASTER) }
    scope :developer, -> { where(access_level: Gitlab::Access::DEVELOPER) }
  end

  def type
    if self.user.present?
      :user
    elsif self.group.present?
      :group
    else
      :role
    end
  end

  def humanize
    return self.user.name if self.user.present?
    return self.group.name if self.group.present?

    self.class.human_access_levels[self.access_level]
  end

  def check_access(user)
    return true if user.is_admin?

    project.team.max_member_access(user.id) >= access_level
  end
end
