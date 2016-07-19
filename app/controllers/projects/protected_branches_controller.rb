class Projects::ProtectedBranchesController < Projects::ApplicationController
  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_admin_project!
  before_action :load_protected_branch, only: [:show, :update, :destroy]

  layout "project_settings"

  def index
    @protected_branches = @project.protected_branches.order(:name).page(params[:page])
    @protected_branch = @project.protected_branches.new
    gon.push({ open_branches: @project.open_branches.map { |br| { text: br.name, id: br.name, title: br.name } } })
  end

  def create
    @project.protected_branches.create(protected_branch_params)
    redirect_to namespace_project_protected_branches_path(@project.namespace,
                                                          @project)
  end

  def show
    @matching_branches = @protected_branch.matching(@project.repository.branches)
  end

  def update
    if @protected_branch && @protected_branch.update_attributes(protected_branch_params)
      respond_to do |format|
        format.json { render json: @protected_branch, status: :ok }
      end
    else
      respond_to do |format|
        format.json { render json: @protected_branch.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @protected_branch.destroy

    respond_to do |format|
      format.html { redirect_to namespace_project_protected_branches_path }
      format.js { head :ok }
    end
  end

  private

  def load_protected_branch
    @protected_branch = @project.protected_branches.find(params[:id])
  end

  def protected_branch_params
    params.require(:protected_branch).permit(:name, :developers_can_push, :developers_can_merge)
  end
end
