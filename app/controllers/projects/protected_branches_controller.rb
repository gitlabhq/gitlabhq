class Projects::ProtectedBranchesController < Projects::ApplicationController
  # Authorize
  before_filter :require_non_empty_project
  before_filter :authorize_admin_project!

  layout "project_settings"

  def index
    @branches = @project.protected_branches.to_a
    @protected_branch = @project.protected_branches.new
  end

  def create
    @project.protected_branches.create(protected_branch_params)
    redirect_to project_protected_branches_path(@project)
  end

  def destroy
    @project.protected_branches.find(params[:id]).destroy

    respond_to do |format|
      format.html { redirect_to project_protected_branches_path }
      format.js { render nothing: true }
    end
  end

  private

  def protected_branch_params
    params.require(:protected_branch).permit(:name)
  end
end
