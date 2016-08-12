class ProtectedBranch::MergeAccessLevel < ActiveRecord::Base
  include ProtectedBranchAccess

  belongs_to :protected_branch
  belongs_to :user
  belongs_to :group

  delegate :project, to: :protected_branch

  validates :access_level, presence: true, inclusion: { in: [Gitlab::Access::MASTER,
                                                             Gitlab::Access::DEVELOPER] }

  scope :by_user, -> (user) { where(user: user ) }

  def self.human_access_levels
    {
      Gitlab::Access::MASTER => "Masters",
      Gitlab::Access::DEVELOPER => "Developers + Masters"
    }.with_indifferent_access
  end

  def check_access(user)
    return true if user.is_admin?
    return user.id == self.user_id if self.user.present?
    return group.users.exists?(user.id) if self.group.present?

    project.team.max_member_access(user.id) >= access_level
  end
end
