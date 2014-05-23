class Projects::BranchesController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_read_project!
  before_filter :require_non_empty_project

  before_filter :authorize_code_access!
  before_filter :authorize_push!, only: [:create, :destroy]

  def index
    @sort = params[:sort] || 'name'
    @branches = @repository.branches_sorted_by(@sort)
    @branches = Kaminari.paginate_array(@branches).page(params[:page]).per(30)
  end

  def recent
    @branches = @repository.recent_branches
  end

  def create
    @branch = CreateBranchService.new.execute(project, params[:branch_name], params[:ref], current_user)

    redirect_to project_tree_path(@project, @branch.name)
  end

  def destroy
    DeleteBranchService.new.execute(project, params[:id], current_user)
    @branch_name = params[:id]

    respond_to do |format|
      format.html { redirect_to project_branches_path(@project) }
      format.js
    end
  end
end
