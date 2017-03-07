class Projects::ProtectedBranchesController < Projects::ApplicationController
  include RepositorySettingsRedirect
  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_admin_project!
  before_action :load_protected_branch, only: [:show, :update, :destroy]

  layout "project_settings"

  def index
    redirect_to_repository_settings(@project)
  end

  def create
    @protected_branch = ::ProtectedBranches::CreateService.new(@project, current_user, protected_branch_params).execute
    unless @protected_branch.persisted?
      flash[:alert] = @protected_branches.errors.full_messages.join(', ').html_safe
    end
    redirect_to_repository_settings(@project)
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
      format.html { redirect_to_repository_settings(@project) }
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
end
