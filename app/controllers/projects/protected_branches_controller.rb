class Projects::ProtectedBranchesController < Projects::ApplicationController
  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_admin_project!
  before_action :load_protected_branch, only: [:show, :update, :destroy]
  before_action :load_protected_branches, only: [:index, :create]

  layout "project_settings"

  def index
    @protected_branch = @project.protected_branches.new
    gon.push({ open_branches: @project.open_branches.map { |br| { text: br.name, id: br.name, title: br.name } },
               push_access_levels: ProtectedBranch::PushAccessLevel.human_access_levels.map { |id, text| { id: id, text: text } },
               merge_access_levels: ProtectedBranch::MergeAccessLevel.human_access_levels.map { |id, text| { id: id, text: text } } })
  end

  def create
    service = ProtectedBranches::CreateService.new(@project, current_user, protected_branch_params)
    if service.execute
      redirect_to namespace_project_protected_branches_path(@project.namespace, @project)
    else
      @protected_branch = service.protected_branch
      render :index
    end
  end

  def show
    @matching_branches = @protected_branch.matching(@project.repository.branches)
  end

  def update
    service = ProtectedBranches::UpdateService.new(@project, current_user, params[:id], protected_branch_params)

    if service.execute
      respond_to do |format|
        format.json { render json: service.protected_branch, status: :ok }
      end
    else
      respond_to do |format|
        format.json { render json: service.protected_branch.errors, status: :unprocessable_entity }
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
    params.require(:protected_branch).permit(:name, :allowed_to_push, :allowed_to_merge)
  end

  def load_protected_branches
    @protected_branches = @project.protected_branches.order(:name).page(params[:page])
  end
end
