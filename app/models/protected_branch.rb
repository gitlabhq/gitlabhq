class ProtectedBranch < ActiveRecord::Base
  include Gitlab::ShellAdapter
  include ProtectedRef

  protected_ref_access_levels :merge, :push

  def self.protected_ref_accessible_to?(ref, user, project:, action:, protected_refs: nil)
    # Masters, owners and admins are allowed to create the default branch
    if default_branch_protected? && project.empty_repo?
      return true if user.admin? || project.team.max_member_access(user.id) > Gitlab::Access::DEVELOPER
    end

    super
  end

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
