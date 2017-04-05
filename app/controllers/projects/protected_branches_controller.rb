class Projects::ProtectedBranchesController < Projects::ProtectedRefsController
  protected

  def project_refs
    @project.repository.branches
  end

  def create_service_class
    ::ProtectedBranches::CreateService
  end

  def update_service_class
    ::ProtectedBranches::UpdateService
  end

  def load_protected_ref
    @protected_ref = @project.protected_branches.find(params[:id])
  end

  def protected_ref_params
    params.require(:protected_branch).permit(:name,
                                             merge_access_levels_attributes: [:access_level, :id],
                                             push_access_levels_attributes: [:access_level, :id])
  end
end
