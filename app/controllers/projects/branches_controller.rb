class Projects::BranchesController < Projects::ApplicationController
  include ActionView::Helpers::SanitizeHelper
  include SortingHelper

  # Authorize
  before_action :require_non_empty_project, except: :create
  before_action :authorize_download_code!
  before_action :authorize_push_code!, only: [:new, :create, :destroy, :destroy_all_merged]

  def index
    @sort = params[:sort].presence || sort_value_name
    @branches = BranchesFinder.new(@repository, params).execute
    @branches = Kaminari.paginate_array(@branches).page(params[:page])

    respond_to do |format|
      format.html do
        @refs_pipelines = @project.pipelines.latest_successful_for_refs(@branches.map(&:name))

        @max_commits = @branches.reduce(0) do |memo, branch|
          diverging_commit_counts = repository.diverging_commit_counts(branch)
          [memo, diverging_commit_counts[:behind], diverging_commit_counts[:ahead]].max
        end
      end
      format.json do
        render json: @branches.map(&:name)
      end
    end
  end

  def recent
    @branches = @repository.recent_branches
  end

  def create
    branch_name = sanitize(strip_tags(params[:branch_name]))
    branch_name = Addressable::URI.unescape(branch_name)

    redirect_to_autodeploy = project.empty_repo? && project.deployment_services.present?

    result = CreateBranchService.new(project, current_user)
        .execute(branch_name, ref)

    if params[:issue_iid]
      issue = IssuesFinder.new(current_user, project_id: @project.id).find_by(iid: params[:issue_iid])
      SystemNoteService.new_issue_branch(issue, @project, current_user, branch_name) if issue
    end

    respond_to do |format|
      format.html do
        if result[:status] == :success
          if redirect_to_autodeploy
            redirect_to url_to_autodeploy_setup(project, branch_name),
              notice: view_context.autodeploy_flash_notice(branch_name)
          else
            redirect_to project_tree_path(@project, branch_name)
          end
        else
          @error = result[:message]
          render action: 'new'
        end
      end

      format.json do
        if result[:status] == :success
          render json: { name: branch_name, url: project_tree_url(@project, branch_name) }
        else
          render json: result[:messsage], status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    @branch_name = Addressable::URI.unescape(params[:id])
    result = DeleteBranchService.new(project, current_user).execute(@branch_name)

    respond_to do |format|
      format.html do
        flash_type = result[:status] == :error ? :alert : :notice
        flash[flash_type] = result[:message]

        redirect_to project_branches_path(@project), status: 303
      end

      format.js { render nothing: true, status: result[:return_code] }
      format.json { render json: { message: result[:message] }, status: result[:return_code] }
    end
  end

  def destroy_all_merged
    DeleteMergedBranchesService.new(@project, current_user).async_execute

    redirect_to project_branches_path(@project),
      notice: 'Merged branches are being deleted. This can take some time depending on the number of branches. Please refresh the page to see changes.'
  end

  private

  def ref
    if params[:ref]
      ref_escaped = sanitize(strip_tags(params[:ref]))
      Addressable::URI.unescape(ref_escaped)
    else
      @project.default_branch || 'master'
    end
  end

  def url_to_autodeploy_setup(project, branch_name)
    project_new_blob_path(
      project,
      branch_name,
      file_name: '.gitlab-ci.yml',
      commit_message: 'Set up auto deploy',
      target_branch: branch_name,
      context: 'autodeploy'
    )
  end
end
