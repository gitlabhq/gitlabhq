class Projects::ProtectedBranchesController < Projects::ApplicationController
  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_admin_project!

  layout "project_settings"

  def index
    @branches = @project.protected_branches.to_a
    @protected_branch = @project.protected_branches.new
  end

  def create
    @project.protected_branches.create(protected_branch_params)
    redirect_to namespace_project_protected_branches_path(@project.namespace,
                                                          @project)
  end

  def update
    protected_branch = @project.protected_branches.find(params[:id])

    if protected_branch &&
       protected_branch.update_attributes(
         developers_can_push: params[:developers_can_push]
       )

      respond_to do |format|
        format.json { render json: protected_branch, status: :ok }
      end
    else
      respond_to do |format|
        format.json { render json: protected_branch.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @project.protected_branches.find(params[:id]).destroy

    respond_to do |format|
      format.html { redirect_to namespace_project_protected_branches_path }
      format.js { render nothing: true }
    end
  end

  private

  def protected_branch_params
    params.require(:protected_branch).permit(:name, :developers_can_push)
  end
end
