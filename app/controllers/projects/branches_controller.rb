class Projects::BranchesController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_read_project!
  before_filter :require_non_empty_project

  before_filter :authorize_admin_project!, only: [:destroy, :create]

  def index
    @branches = Kaminari.paginate_array(@repository.branches).page(params[:page]).per(30)
  end

  def create
    # TODO: implement
  end

  def destroy
    branch = @project.repository.branches.find { |branch| branch.name == params[:id] }

    if branch && @project.repository.rm_branch(branch.name)
      Event.create_rm_branch(@project, current_user, branch)
    end

    respond_to do |format|
      format.html { redirect_to project_branches_path }
      format.js { render nothing: true }
    end
  end
end
