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
    
    ::Gitlab::GitAccess.can_push_to_branch?(current_user, project, branch_name)
  end
end
