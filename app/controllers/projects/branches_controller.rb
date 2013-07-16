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
    @project.repository.rm_branch(params[:id])

    respond_to do |format|
      format.html { redirect_to project_branches_path }
      format.js { render nothing: true }
    end
  end
end
