class ProtectedBranch < ActiveRecord::Base
  include Gitlab::ShellAdapter
  include ProtectedRef

  protected_ref_access_levels :merge, :push

  # Check if branch name is marked as protected in the system
  def self.protected?(project, ref_name)
    return true if project.empty_repo? && default_branch_protected?

    refs = project.protected_branches.select(:name)

    self.matching(ref_name, protected_refs: refs).present?
  end

  def self.default_branch_protected?
    Gitlab::CurrentSettings.default_branch_protection == Gitlab::Access::PROTECTION_FULL ||
      Gitlab::CurrentSettings.default_branch_protection == Gitlab::Access::PROTECTION_DEV_CAN_MERGE
  end
end
