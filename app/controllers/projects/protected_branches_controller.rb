class Projects::ProtectedBranchesController < Projects::ApplicationController
  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_admin_project!
  before_action :load_protected_branch, only: [:show, :update, :destroy]
  before_action :load_protected_branches, only: [:index]

  layout "project_settings"

  def index
    @protected_branch = @project.protected_branches.new
    load_gon_index
  end

  def create
    @protected_branch = ::ProtectedBranches::CreateService.new(@project, current_user, protected_branch_params).execute
    if @protected_branch.persisted?
      redirect_to namespace_project_protected_branches_path(@project.namespace, @project)
    else
      load_protected_branches
      load_gon_index
      render :index
    end
  end

  def show
    @matching_branches = @protected_branch.matching(@project.repository.branches)
  end

  def update
    @protected_branch = ::ProtectedBranches::UpdateService.new(@project, current_user, protected_branch_params).execute(@protected_branch)

    if @protected_branch.valid?
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
    params.require(:protected_branch).permit(:name,
                                             merge_access_levels_attributes: [:access_level, :id],
                                             push_access_levels_attributes: [:access_level, :id])
  end

  def load_protected_branches
    @protected_branches = @project.protected_branches.order(:name).page(params[:page])
  end

  def access_levels_options
    {
      push_access_levels: ProtectedBranch::PushAccessLevel.human_access_levels.map { |id, text| { id: id, text: text, before_divider: true } },
      merge_access_levels: ProtectedBranch::MergeAccessLevel.human_access_levels.map { |id, text| { id: id, text: text, before_divider: true } }
    }
  end

  def load_gon_index
    params = { open_branches: @project.open_branches.map { |br| { text: br.name, id: br.name, title: br.name } } }
    gon.push(params.merge(access_levels_options))
  end
end
