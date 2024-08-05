# frozen_string_literal: true

module ProtectedBranchesHelper
  def protected_branch_can_admin_entity?(protected_branch_entity)
    if protected_branch_entity.is_a?(Group)
      can?(current_user, :admin_group, protected_branch_entity)
    else
      can?(current_user, :admin_protected_branch, protected_branch_entity)
    end
  end

  def protected_branch_path_by_entity(protected_branch, protected_branch_entity)
    if protected_branch_entity.is_a?(Group)
      group_protected_branch_path(protected_branch_entity, protected_branch)
    else
      project_protected_branch_path(protected_branch_entity, protected_branch)
    end
  end
end

ProtectedBranchesHelper.prepend_mod
