class Projects::MergeRequestsController < Projects::MergeRequests::ApplicationController
  include ToggleSubscriptionAction
  include IssuableActions
  include RendersNotes
  include ToggleAwardEmoji
  include IssuableCollections

  prepend ::EE::Projects::MergeRequestsController

  skip_before_action :merge_request, only: [:index, :bulk_update]
  skip_before_action :ensure_ref_fetched, only: [:index, :bulk_update]

  before_action :authorize_update_merge_request!, only: [:close, :edit, :update, :remove_wip, :sort]

  before_action :authenticate_user!, only: [:assign_related_issues]

  def index
    @collection_type    = "MergeRequest"
    @merge_requests     = merge_requests_collection
    @merge_requests     = @merge_requests.page(params[:page])
    @merge_requests     = @merge_requests.preload(merge_request_diff: :merge_request)
    @issuable_meta_data = issuable_meta_data(@merge_requests, @collection_type)

    if @merge_requests.out_of_range? && @merge_requests.total_pages != 0
      return redirect_to url_for(params.merge(page: @merge_requests.total_pages, only_path: true))
    end

    if params[:label_name].present?
      labels_params = { project_id: @project.id, title: params[:label_name] }
      @labels = LabelsFinder.new(current_user, labels_params).execute
    end

    @users = []
    if params[:assignee_id].present?
      assignee = User.find_by_id(params[:assignee_id])
      @users.push(assignee) if assignee
    end

    if params[:author_id].present?
      author = User.find_by_id(params[:author_id])
      @users.push(author) if author
    end

    respond_to do |format|
      format.html
      format.json do
        render json: {
          html: view_to_html_string("projects/merge_requests/_merge_requests"),
          labels: @labels.as_json(methods: :text_color)
        }
      end
    end
  end

  def show
    validates_merge_request
    ensure_ref_fetched
    close_merge_request_without_source_project
    check_if_can_be_merged

    respond_to do |format|
      format.html do
        # Build a note object for comment form
        @note = @project.notes.new(noteable: @merge_request)

        @discussions = @merge_request.discussions
        @notes = prepare_notes_for_rendering(@discussions.flat_map(&:notes))

        @noteable = @merge_request
        @commits_count = @merge_request.commits_count

        if @merge_request.locked_long_ago?
          @merge_request.unlock_mr
          @merge_request.close
        end

        labels

        set_pipeline_variables
      end

      format.json do
        Gitlab::PollingInterval.set_header(response, interval: 10_000)

        render json: serializer.represent(@merge_request, basic: params[:basic])
      end

      format.patch  do
        return render_404 unless @merge_request.diff_refs

        send_git_patch @project.repository, @merge_request.diff_refs
      end

      format.diff do
        return render_404 unless @merge_request.diff_refs

        send_git_diff @project.repository, @merge_request.diff_refs
      end
    end
  end

  def commits
    # Get commits from repository
    # or from cache if already merged
    @commits = @merge_request.commits
    @note_counts = Note.where(commit_id: @commits.map(&:id))
      .group(:commit_id).count

    render json: { html: view_to_html_string('projects/merge_requests/_commits') }
  end

  def pipelines
    @pipelines = @merge_request.all_pipelines

    Gitlab::PollingInterval.set_header(response, interval: 10_000)

    render json: {
      pipelines: PipelineSerializer
        .new(project: @project, current_user: @current_user)
        .represent(@pipelines),
      count: {
        all: @pipelines.count
      }
    }
  end

  def edit
    define_edit_vars
  end

  def update
    @merge_request = ::MergeRequests::UpdateService.new(project, current_user, merge_request_params).execute(@merge_request)

    respond_to do |format|
      format.html do
        if @merge_request.valid?
          redirect_to([@merge_request.target_project.namespace.becomes(Namespace), @merge_request.target_project, @merge_request])
        else
          define_edit_vars

          render :edit
        end
      end

      format.json do
        render json: @merge_request.to_json(include: { milestone: {}, assignee: { only: [:name, :username], methods: [:avatar_url] }, labels: { methods: :text_color } }, methods: [:task_status, :task_status_short])
      end
    end
  rescue ActiveRecord::StaleObjectError
    define_edit_vars if request.format.html?

    render_conflict_response
  end

  def remove_wip
    @merge_request = ::MergeRequests::UpdateService
      .new(project, current_user, wip_event: 'unwip')
      .execute(@merge_request)

    render json: serializer.represent(@merge_request)
  end

  def commit_change_content
    render partial: 'projects/merge_requests/widget/commit_change_content', layout: false
  end

  def cancel_merge_when_pipeline_succeeds
    unless @merge_request.can_cancel_merge_when_pipeline_succeeds?(current_user)
      return access_denied!
    end

    ::MergeRequests::MergeWhenPipelineSucceedsService
      .new(@project, current_user)
      .cancel(@merge_request)

    render json: serializer.represent(@merge_request)
  end

  def merge
    return access_denied! unless @merge_request.can_be_merged_by?(current_user)
    return render_404 unless @merge_request.approved?

    status = merge!

    if @merge_request.merge_error
      render json: { status: status, merge_error: @merge_request.merge_error }
    else
      render json: { status: status }
    end
  end

  def assign_related_issues
    result = ::MergeRequests::AssignIssuesService.new(project, current_user, merge_request: @merge_request).execute

    case result[:count]
    when 0
      flash[:error] = "Failed to assign you issues related to the merge request"
    when 1
      flash[:notice] = "1 issue has been assigned to you"
    else
      flash[:notice] = "#{result[:count]} issues have been assigned to you"
    end

    redirect_to(merge_request_path(@merge_request))
  end

  def pipeline_status
    render json: PipelineSerializer
      .new(project: @project, current_user: @current_user)
      .represent_status(@merge_request.head_pipeline)
  end

  def ci_environments_status
    environments =
      begin
        @merge_request.environments_for(current_user).map do |environment|
          project = environment.project
          deployment = environment.first_deployment_for(@merge_request.diff_head_commit)

          stop_url =
            if environment.stop_action? && can?(current_user, :create_deployment, environment)
              stop_project_environment_path(project, environment)
            end

          metrics_url =
            if can?(current_user, :read_environment, environment) && environment.has_metrics?
              metrics_project_environment_deployment_path(environment.project, environment, deployment)
            end

          {
            id: environment.id,
            name: environment.name,
            url: project_environment_path(project, environment),
            metrics_url: metrics_url,
            stop_url: stop_url,
            external_url: environment.external_url,
            external_url_formatted: environment.formatted_external_url,
            deployed_at: deployment.try(:created_at),
            deployed_at_formatted: deployment.try(:formatted_deployment_time)
          }
        end.compact
      end

    render json: environments
  end

  protected

  alias_method :subscribable_resource, :merge_request
  alias_method :issuable, :merge_request
  alias_method :awardable, :merge_request

  def authorize_update_merge_request!
    return render_404 unless can?(current_user, :update_merge_request, @merge_request)
  end

  def authorize_admin_merge_request!
    return render_404 unless can?(current_user, :admin_merge_request, @merge_request)
  end

  def validates_merge_request
    # Show git not found page
    # if there is no saved commits between source & target branch
    if @merge_request.has_no_commits?
      # and if target branch doesn't exist
      return invalid_mr unless @merge_request.target_branch_exists?
    end
  end

  def invalid_mr
    # Render special view for MR with removed target branch
    render 'invalid'
  end

  def merge_params
    params.permit(merge_params_attributes)
  end

  def merge_params_attributes
    [:should_remove_source_branch, :commit_message]
  end

  def merge_when_pipeline_succeeds_active?
    params[:merge_when_pipeline_succeeds].present? &&
      @merge_request.head_pipeline && @merge_request.head_pipeline.active?
  end

  def close_merge_request_without_source_project
    if !@merge_request.source_project && @merge_request.open?
      @merge_request.close
    end
  end

  private

  def check_if_can_be_merged
    @merge_request.check_if_can_be_merged
  end

  def merge!
    # Disable the CI check if merge_when_pipeline_succeeds is enabled since we have
    # to wait until CI completes to know
    unless @merge_request.mergeable?(skip_ci_check: merge_when_pipeline_succeeds_active?)
      return :failed
    end

    merge_request_service = MergeRequests::MergeService.new(@project, current_user, merge_params)

    unless merge_request_service.hooks_validation_pass?(@merge_request)
      return :hook_validation_error
    end

    return :sha_mismatch if params[:sha] != @merge_request.diff_head_sha

    @merge_request.update(merge_error: nil, squash: merge_params[:squash])

    if params[:merge_when_pipeline_succeeds].present?
      return :failed unless @merge_request.head_pipeline

      if @merge_request.head_pipeline.active?
        ::MergeRequests::MergeWhenPipelineSucceedsService
          .new(@project, current_user, merge_params)
          .execute(@merge_request)

        :merge_when_pipeline_succeeds
      elsif @merge_request.head_pipeline.success?
        # This can be triggered when a user clicks the auto merge button while
        # the tests finish at about the same time
        MergeWorker.perform_async(@merge_request.id, current_user.id, params)

        :success
      else
        :failed
      end
    else
      MergeWorker.perform_async(@merge_request.id, current_user.id, params)

      :success
    end
  end

  def serializer
    MergeRequestSerializer.new(current_user: current_user, project: merge_request.project)
  end

  def define_edit_vars
    @source_project = @merge_request.source_project
    @target_project = @merge_request.target_project
    @target_branches = @merge_request.target_project.repository.branch_names
  end
end
