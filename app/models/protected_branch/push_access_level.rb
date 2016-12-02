class ProtectedBranch::PushAccessLevel < ActiveRecord::Base
  include ProtectedBranchAccess

<<<<<<< HEAD
  belongs_to :protected_branch
  belongs_to :user
  belongs_to :group

  delegate :project, to: :protected_branch

=======
>>>>>>> 14046b9c734e5e6506d63276f39f3f9d770c3699
  validates :access_level, presence: true, inclusion: { in: [Gitlab::Access::MASTER,
                                                             Gitlab::Access::DEVELOPER,
                                                             Gitlab::Access::NO_ACCESS] }

  scope :by_user, -> (user) { where(user: user ) }
  scope :by_group, -> (group) { where(group: group ) }

  def self.human_access_levels
    {
      Gitlab::Access::MASTER => "Masters",
      Gitlab::Access::DEVELOPER => "Developers + Masters",
      Gitlab::Access::NO_ACCESS => "No one"
    }.with_indifferent_access
  end

  def check_access(user)
    return false if access_level == Gitlab::Access::NO_ACCESS
<<<<<<< HEAD
    return true if user.is_admin?
    return user.id == self.user_id if self.user.present?
    return group.users.exists?(user.id) if self.group.present?
=======
>>>>>>> 14046b9c734e5e6506d63276f39f3f9d770c3699

    super
  end
end
