# frozen_string_literal: true

class Projects::BranchesController < Projects::ApplicationController
  include ActionView::Helpers::SanitizeHelper
  include SortingHelper

  # Authorize
  before_action :require_non_empty_project, except: :create
  before_action :authorize_read_code!
  before_action :authorize_push_code!, only: [:new, :create, :destroy, :destroy_all_merged]

  # Support legacy URLs
  before_action :redirect_for_legacy_index_sort_or_search, only: [:index]
  before_action :limit_diverging_commit_counts!, only: [:diverging_commit_counts]

  feature_category :source_code_management
  urgency :low, [:index, :diverging_commit_counts, :create, :destroy]

  def index
    respond_to do |format|
      format.html do
        @mode = fetch_mode
        next render_404 unless @mode

        @sort = sort_param || default_sort
        @overview_max_branches = 5

        # Fetch branches for the specified mode
        fetch_branches_by_mode
        fetch_merge_requests_for_branches

        @refs_pipelines = @project.ci_pipelines.latest_successful_for_refs(@branches.map(&:name))
        @merged_branch_names = repository.merged_branch_names(@branches.map(&:name))
        @branch_pipeline_statuses = Ci::CommitStatusesFinder.new(@project, repository, current_user, @branches).execute

        # https://gitlab.com/gitlab-org/gitlab/-/issues/22851
        Gitlab::GitalyClient.allow_n_plus_1_calls do
          render
        end
      rescue Gitlab::Git::CommandError
        @gitaly_unavailable = true
        render status: :service_unavailable
      end
      format.json do
        branches = BranchesFinder.new(@repository, branches_params).execute
        branches = Kaminari.paginate_array(branches).page(branches_params[:page])
        render json: branches.map(&:name)
      end
    end
  end

  def diverging_commit_counts
    respond_to do |format|
      format.json do
        service = ::Branches::DivergingCommitCountsService.new(repository)
        branches = BranchesFinder.new(repository, params.permit(names: [])).execute

        Gitlab::GitalyClient.allow_n_plus_1_calls do
          render json: branches.to_h { |branch| [branch.name, service.call(branch)] }
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

      if issue
        SystemNoteService.new_issue_branch(issue, target_project, current_user, branch_name, branch_project: @project)
      end
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
          render json: result[:message], status: :unprocessable_entity
        end
      end
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def destroy
    result = ::Branches::DeleteService.new(project, current_user).execute(params[:id])

    respond_to do |format|
      format.html do
        flash_type = result.error? ? :alert : :notice
        flash[flash_type] = result.message

        redirect_back_or_default(default: project_branches_path(@project), options: { status: :see_other })
      end

      format.js { head result.http_status }
      format.json { render json: { message: result.message }, status: result.http_status }
    end
  end

  def destroy_all_merged
    ::Branches::DeleteMergedService.new(@project, current_user).async_execute

    redirect_to project_branches_path(@project),
      notice: _('Merged branches are being deleted. This can take some time depending on the number of branches. ' \
        'Please refresh the page to see changes.')
  end

  private

  def sort_param
    sort = branches_params[:sort].presence

    unless sort.in?(supported_sort_options)
      flash.now[:alert] = _("Unsupported sort value.")
      sort = nil
    end

    sort
  end

  def default_sort
    'stale' == @mode ? SORT_UPDATED_OLDEST : SORT_UPDATED_RECENT
  end

  def supported_sort_options
    [nil, SORT_NAME, SORT_UPDATED_OLDEST, SORT_UPDATED_RECENT]
  end

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
      @project.default_branch_or_main
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
    if request.format != :json && !branches_params[:state].presence && [:sort, :search, :page].any? do |key|
      branches_params[key].presence
    end
      redirect_to project_branches_filtered_path(@project, state: 'all'),
        notice: _('Update your bookmarked URLs as filtered/sorted branches URL has been changed.')
    end
  end

  def fetch_branches_by_mode
    return fetch_branches_for_overview if @mode == 'overview'

    @branches, @prev_path, @next_path =
      Projects::BranchesByModeService.new(@project, branches_params.merge(sort: @sort, mode: @mode)).execute
  end

  def fetch_merge_requests_for_branches
    @related_merge_requests = @project
                                .source_of_merge_requests
                                .including_target_project
                                .by_target_branch(@project.default_branch)
                                .by_sorted_source_branches(@branches.map(&:name))
                                .group_by(&:source_branch)
  end

  def fetch_branches_for_overview
    # Here we get one more branch to indicate if there are more data we're not showing
    limit = @overview_max_branches + 1

    @active_branches =
      BranchesFinder.new(@repository, { per_page: limit, sort: SORT_UPDATED_RECENT })
        .execute(gitaly_pagination: true).select(&:active?)
    @stale_branches =
      BranchesFinder.new(@repository, { per_page: limit, sort: SORT_UPDATED_OLDEST })
        .execute(gitaly_pagination: true).select(&:stale?)

    @branches = @active_branches + @stale_branches
  end

  def fetch_mode
    state = branches_params[:state].presence

    return 'overview' unless state

    state.presence_in(%w[active stale all overview])
  end

  def confidential_issue_project
    return if params[:confidential_issue_project_id].blank?

    confidential_issue_project = Project.find(params[:confidential_issue_project_id])

    return unless can?(current_user, :update_issue, confidential_issue_project)

    confidential_issue_project
  end

  def branches_params
    params.permit(:page, :state, :sort, :search, :page_token, :offset)
  end
end
