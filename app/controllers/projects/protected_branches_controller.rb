# frozen_string_literal: true

class Projects::ProtectedBranchesController < Projects::ProtectedRefsController
  def show
    super

    render 'protected_branches/show'
  end

  protected

  def ref_type
    :branches
  end

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

  def protected_ref_params(*attrs)
    attrs = ([:name,
      :allow_force_push,
      { merge_access_levels_attributes: access_level_attributes,
        push_access_levels_attributes: access_level_attributes }] + attrs).uniq

    params.require(:protected_branch).permit(attrs)
  end

  private

  def handle_gitaly_error(exception)
    Gitlab::ErrorTracking.track_exception(exception)

    @gitaly_unavailable = true

    render 'protected_branches/show', status: :service_unavailable
  end
end

Projects::ProtectedBranchesController.prepend_mod_with('Projects::ProtectedBranchesController')
