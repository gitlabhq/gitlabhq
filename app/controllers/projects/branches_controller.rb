# frozen_string_literal: true

class Projects::BranchesController < Projects::ApplicationController
  include ActionView::Helpers::SanitizeHelper
  include SortingHelper

  # Authorize
  before_action :require_non_empty_project, except: :create
  before_action :authorize_download_code!
  before_action :authorize_push_code!, only: [:new, :create, :destroy, :destroy_all_merged]

  # Support legacy URLs
  before_action :redirect_for_legacy_index_sort_or_search, only: [:index]
  before_action :limit_diverging_commit_counts!, only: [:diverging_commit_counts]

  def index
    respond_to do |format|
      format.html do
        @sort = params[:sort].presence || sort_value_recently_updated
        @mode = params[:state].presence || 'overview'
        @overview_max_branches = 5

        # Fetch branches for the specified mode
        fetch_branches_by_mode

        @refs_pipelines = @project.ci_pipelines.latest_successful_for_refs(@branches.map(&:name))
        @merged_branch_names = repository.merged_branch_names(@branches.map(&:name))

        # https://gitlab.com/gitlab-org/gitlab-foss/issues/48097
        Gitlab::GitalyClient.allow_n_plus_1_calls do
          render
        end
      end
      format.json do
        branches = BranchesFinder.new(@repository, params).execute
        branches = Kaminari.paginate_array(branches).page(params[:page])
        render json: branches.map(&:name)
      end
    end
  end

  def recent
    @branches = @repository.recent_branches
  end

  def diverging_commit_counts
    respond_to do |format|
      format.json do
        service = ::Branches::DivergingCommitCountsService.new(repository)
        branches = BranchesFinder.new(repository, params.permit(names: [])).execute

        Gitlab::GitalyClient.allow_n_plus_1_calls do
          render json: branches.map { |branch| [branch.name, service.call(branch)] }.to_h
        end
      end
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def create
    branch_name = strip_tags(sanitize(params[:branch_name]))
    branch_name = Addressable::URI.unescape(branch_name)

    redirect_to_autodeploy = project.empty_repo? && project.deployment_platform.present?

    result = ::Branches::CreateService.new(project, current_user)
        .execute(branch_name, ref)

    success = (result[:status] == :success)

    if params[:issue_iid] && success
      target_project = confidential_issue_project || @project
      issue = IssuesFinder.new(current_user, project_id: target_project.id).find_by(iid: params[:issue_iid])
      SystemNoteService.new_issue_branch(issue, target_project, current_user, branch_name, branch_project: @project) if issue
    end

    respond_to do |format|
      format.html do
        if success
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
        if success
          render json: { name: branch_name, url: project_tree_url(@project, branch_name) }
        else
          render json: result[:messsage], status: :unprocessable_entity
        end
      end
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def destroy
    @branch_name = Addressable::URI.unescape(params[:id])
    result = ::Branches::DeleteService.new(project, current_user).execute(@branch_name)

    respond_to do |format|
      format.html do
        flash_type = result.error? ? :alert : :notice
        flash[flash_type] = result.message

        redirect_to project_branches_path(@project), status: :see_other
      end

      format.js { head result.http_status }
      format.json { render json: { message: result.message }, status: result.http_status }
    end
  end

  def destroy_all_merged
    ::Branches::DeleteMergedService.new(@project, current_user).async_execute

    redirect_to project_branches_path(@project),
      notice: _('Merged branches are being deleted. This can take some time depending on the number of branches. Please refresh the page to see changes.')
  end

  private

  # It can be expensive to calculate the diverging counts for each
  # branch. Normally the frontend should be specifying a set of branch
  # names, but prior to
  # https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/32496, the
  # frontend could omit this set. To prevent excessive I/O, we require
  # that a list of names be specified.
  def limit_diverging_commit_counts!
    limit = Kaminari.config.default_per_page

    # If we don't have many branches in the repository, then go ahead.
    return if project.repository.branch_count <= limit
    return if params[:names].present? && Array(params[:names]).length <= limit

    render json: { error: "Specify at least one and at most #{limit} branch names" }, status: :unprocessable_entity
  end

  def ref
    if params[:ref]
      ref_escaped = strip_tags(sanitize(params[:ref]))
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

  def redirect_for_legacy_index_sort_or_search
    # Normalize a legacy URL with redirect
    if request.format != :json && !params[:state].presence && [:sort, :search, :page].any? { |key| params[key].presence }
      redirect_to project_branches_filtered_path(@project, state: 'all'), notice: _('Update your bookmarked URLs as filtered/sorted branches URL has been changed.')
    end
  end

  def fetch_branches_by_mode
    if @mode == 'overview'
      # overview mode
      @active_branches, @stale_branches = BranchesFinder.new(@repository, sort: sort_value_recently_updated).execute.partition(&:active?)
      # Here we get one more branch to indicate if there are more data we're not showing
      @active_branches = @active_branches.first(@overview_max_branches + 1)
      @stale_branches = @stale_branches.first(@overview_max_branches + 1)
      @branches = @active_branches + @stale_branches
    else
      # active/stale/all view mode
      @branches = BranchesFinder.new(@repository, params.merge(sort: @sort)).execute
      @branches = @branches.select { |b| b.state.to_s == @mode } if %w[active stale].include?(@mode)
      @branches = Kaminari.paginate_array(@branches).page(params[:page])
    end
  end

  def confidential_issue_project
    return unless helpers.create_confidential_merge_request_enabled?
    return if params[:confidential_issue_project_id].blank?

    confidential_issue_project = Project.find(params[:confidential_issue_project_id])

    return unless can?(current_user, :update_issue, confidential_issue_project)

    confidential_issue_project
  end
end
