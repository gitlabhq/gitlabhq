class Projects::BranchesController < Projects::ApplicationController
  include ActionView::Helpers::SanitizeHelper
  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_download_code!
  before_action :authorize_push_code!, only: [:create, :destroy]

  def index
    @sort = params[:sort] || 'name'
    @branches = @repository.branches_sorted_by(@sort)
    @branches = Kaminari.paginate_array(@branches).page(params[:page]).per(PER_PAGE)
  end

  def recent
    @branches = @repository.recent_branches
  end

  def create
    branch_name = sanitize(strip_tags(params[:branch_name]))
    branch_name = Addressable::URI.unescape(branch_name)
    ref = sanitize(strip_tags(params[:ref]))
    ref = Addressable::URI.unescape(ref)
    result = CreateBranchService.new(project, current_user).
        execute(branch_name, ref)

    if result[:status] == :success
      @branch = result[:branch]
      redirect_to namespace_project_tree_path(@project.namespace, @project,
                                              @branch.name)
    else
      @error = result[:message]
      render action: 'new'
    end
  end

  def destroy
    @branch_name = Addressable::URI.unescape(params[:id])
    status = DeleteBranchService.new(project, current_user).execute(@branch_name)
    respond_to do |format|
      format.html do
        redirect_to namespace_project_branches_path(@project.namespace,
                                                    @project)
      end
      format.js { render status: status[:return_code] }
    end
  end
end
