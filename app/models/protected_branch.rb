# frozen_string_literal: true

class ProtectedBranch < ApplicationRecord
  include ProtectedRef

  scope :requiring_code_owner_approval,
        -> { where(code_owner_approval_required: true) }

  protected_ref_access_levels :merge, :push

  def self.protected_ref_accessible_to?(ref, user, project:, action:, protected_refs: nil)
    # Maintainers, owners and admins are allowed to create the default branch
    if default_branch_protected? && project.empty_repo?
      return true if user.admin? || project.team.max_member_access(user.id) > Gitlab::Access::DEVELOPER
    end

    super
  end

  # Check if branch name is marked as protected in the system
  def self.protected?(project, ref_name)
    return true if project.empty_repo? && default_branch_protected?

    self.matching(ref_name, protected_refs: protected_refs(project)).present?
  end

  def self.any_protected?(project, ref_names)
    protected_refs(project).any? do |protected_ref|
      ref_names.any? do |ref_name|
        protected_ref.matches?(ref_name)
      end
    end
  end

  def self.default_branch_protected?
    Gitlab::CurrentSettings.default_branch_protection == Gitlab::Access::PROTECTION_FULL ||
      Gitlab::CurrentSettings.default_branch_protection == Gitlab::Access::PROTECTION_DEV_CAN_MERGE
  end

  def self.protected_refs(project)
    project.protected_branches
  end

  def self.branch_requires_code_owner_approval?(project, branch_name)
    # NOOP
    #
  end
end

ProtectedBranch.prepend_if_ee('EE::ProtectedBranch')
