class ProtectedBranch::MergeAccessLevel < ActiveRecord::Base
  include ProtectedBranchAccess

  belongs_to :user
  belongs_to :group

  validates :access_level, presence: true, inclusion: { in: [Gitlab::Access::MASTER,
                                                             Gitlab::Access::DEVELOPER] }

  scope :by_user, -> (user) { where(user: user ) }
  scope :by_group, -> (group) { where(group: group ) }

  def self.human_access_levels
    {
      Gitlab::Access::MASTER => "Masters",
      Gitlab::Access::DEVELOPER => "Developers + Masters"
    }.with_indifferent_access
  end
end
