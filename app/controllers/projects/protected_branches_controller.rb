class Projects::ProtectedBranchesController < Projects::ProtectedRefsController
  protected

  def protected_ref
    @protected_branch
  end

  def protected_ref=(val)
    @protected_branch = val
  end

  def matching_refs=(val)
    @matching_branches = val
  end

  def project_refs
    @project.repository.branches
  end

  def create_service
    ::ProtectedBranches::CreateService
  end

  def update_service
    ::ProtectedBranches::UpdateService
  end

  def load_protected_ref
    self.protected_ref = @project.protected_branches.find(params[:id])
  end

  def access_levels
    [:merge_access_levels, :push_access_levels]
  end

  def protected_ref_params
    params.require(:protected_branch).permit(:name,
                                             merge_access_levels_attributes: [:access_level, :id, :user_id, :_destroy, :group_id],
                                             push_access_levels_attributes: [:access_level, :id, :user_id, :_destroy, :group_id])
  end
end
