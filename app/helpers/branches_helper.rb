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
end
