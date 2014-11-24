class Projects::BranchesController < Projects::ApplicationController
  include ActionView::Helpers::SanitizeHelper
  # Authorize
  before_filter :require_non_empty_project

  before_filter :authorize_download_code!
  before_filter :authorize_push_code!, only: [:create, :destroy]

  def index
    @sort = params[:sort] || 'name'
    @branches = @repository.branches_sorted_by(@sort)
    @branches = Kaminari.paginate_array(@branches).page(params[:page]).per(30)
  end

  def recent
    @branches = @repository.recent_branches
  end

  def create
    branch_name = sanitize(strip_tags(params[:branch_name]))
    ref = sanitize(strip_tags(params[:ref]))
    result = CreateBranchService.new(project, current_user).
        execute(branch_name, ref)

    if result[:status] == :success
      @branch = result[:branch]
      redirect_to project_tree_path(@project, @branch.name)
    else
      @error = result[:message]
      render action: 'new'
    end
  end

  def destroy
    DeleteBranchService.new(project, current_user).execute(params[:id])
    @branch_name = params[:id]

    respond_to do |format|
      format.html { redirect_to project_branches_path(@project) }
      format.js
    end
  end
end
