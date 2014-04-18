class Projects::BranchesController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_read_project!
  before_filter :require_non_empty_project

  before_filter :authorize_code_access!
  before_filter :authorize_push!, only: [:create]
  before_filter :authorize_admin_project!, only: [:destroy]

  def index
    @branches = Kaminari.paginate_array(@repository.branches).page(params[:page]).per(30)
  end

  def recent
    @branches = @repository.recent_branches
  end

  def create
    CreateBranchService.new.execute(project, params[:branch_name], params[:ref], current_user)

    redirect_to project_branches_path(@project)
  end

  def destroy
    branch = @repository.find_branch(params[:id])

    if branch && @repository.rm_branch(branch.name)
      Event.create_ref_event(@project, current_user, branch, 'rm')
    end

    respond_to do |format|
      format.html { redirect_to project_branches_path(@project) }
      format.js { render nothing: true }
    end
  end
end
