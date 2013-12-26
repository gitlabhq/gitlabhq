class Projects::ProtectedBranchesController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_read_project!
  before_filter :require_non_empty_project

  before_filter :authorize_admin_project!, only: [:destroy, :create]

  def index
    @branches = @project.protected_branches.to_a
    @protected_branch = @project.protected_branches.new
  end

  def create
    @project.protected_branches.create(params[:protected_branch])
    redirect_to project_protected_branches_path(@project)
  end

  def destroy
    @project.protected_branches.find(params[:id]).destroy

    respond_to do |format|
      format.html { redirect_to project_protected_branches_path }
      format.js { render nothing: true }
    end
  end
end
