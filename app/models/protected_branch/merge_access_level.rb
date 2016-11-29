class ProtectedBranch::MergeAccessLevel < ActiveRecord::Base
  include ProtectedBranchAccess
  include ProtectedBranchAccessEe

  validates :access_level, presence: true, inclusion: { in: [Gitlab::Access::MASTER,
                                                             Gitlab::Access::DEVELOPER] }

  def self.human_access_levels
    {
      Gitlab::Access::MASTER => "Masters",
      Gitlab::Access::DEVELOPER => "Developers + Masters"
    }.with_indifferent_access
  end
end
