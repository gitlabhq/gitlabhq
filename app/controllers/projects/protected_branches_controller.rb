class Projects::ProtectedBranchesController < Projects::ProtectedRefsController
  protected

  def project_refs
    @project.repository.branches
  end

  def service_namespace
    ::ProtectedBranches
  end

  def load_protected_ref
    @protected_ref = @project.protected_branches.find(params[:id])
  end

  def access_levels
    [:merge_access_levels, :push_access_levels]
  end

  def protected_ref_params
    params.require(:protected_branch).permit(:name,
                                             merge_access_levels_attributes: access_level_attributes,
                                             push_access_levels_attributes: access_level_attributes)
  end
end
