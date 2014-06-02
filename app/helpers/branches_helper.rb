module BranchesHelper
  def can_remove_branch?(project, branch_name)
    if project.protected_branch? branch_name
      false
    elsif branch_name == project.repository.root_ref
      false
    else
      can?(current_user, :push_code, project)
    end
  end

  def can_push_branch?(project, branch_name)
    return false unless project.repository.branch_names.include?(branch_name)
    action = if project.protected_branch?(branch_name)
               :push_code_to_protected_branches
             else
               :push_code
             end

    current_user.can?(action, project)
  end
end
