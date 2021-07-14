# frozen_string_literal: true

class Projects::MergeRequestsController < Projects::MergeRequests::ApplicationController
  include ToggleSubscriptionAction
  include IssuableActions
  include RendersNotes
  include RendersCommits
  include RendersAssignees
  include ToggleAwardEmoji
  include IssuableCollections
  include RecordUserLastActivity
  include SourcegraphDecorator
  include DiffHelper

  skip_before_action :merge_request, only: [:index, :bulk_update, :export_csv]
  before_action :apply_diff_view_cookie!, only: [:show]
  before_action :disable_query_limiting, only: [:assign_related_issues, :update]
  before_action :authorize_update_issuable!, only: [:close, :edit, :update, :remove_wip, :sort]
  before_action :authorize_read_actual_head_pipeline!, only: [
    :test_reports,
    :exposed_artifacts,
    :coverage_reports,
    :terraform_reports,
    :accessibility_reports,
    :codequality_reports,
    :codequality_mr_diff_reports
  ]
  before_action :set_issuables_index, only: [:index]
  before_action :authenticate_user!, only: [:assign_related_issues]
  before_action :check_user_can_push_to_source_branch!, only: [:rebase]
  before_action only: [:show] do
    push_frontend_feature_flag(:file_identifier_hash)
    push_frontend_feature_flag(:merge_request_widget_graphql, @project, default_enabled: :yaml)
    push_frontend_feature_flag(:default_merge_ref_for_diffs, @project, default_enabled: :yaml)
    push_frontend_feature_flag(:core_security_mr_widget_counts, @project)
    push_frontend_feature_flag(:local_file_reviews, default_enabled: :yaml)
    push_frontend_feature_flag(:paginated_notes, @project, default_enabled: :yaml)
    push_frontend_feature_flag(:confidential_notes, @project, default_enabled: :yaml)
    push_frontend_feature_flag(:usage_data_i_testing_summary_widget_total, @project, default_enabled: :yaml)
    push_frontend_feature_flag(:improved_emoji_picker, project, default_enabled: :yaml)
    push_frontend_feature_flag(:diffs_virtual_scrolling, project, default_enabled: :yaml)

    # Usage data feature flags
    push_frontend_feature_flag(:users_expanding_widgets_usage_data, @project, default_enabled: :yaml)
    push_frontend_feature_flag(:diff_settings_usage_data, default_enabled: :yaml)

    experiment(:invite_members_in_comment, namespace: @project.root_ancestor) do |experiment_instance|
      experiment_instance.exclude! unless helpers.can_import_members?

      experiment_instance.use {}
      experiment_instance.try(:invite_member_link) {}

      experiment_instance.track(:view, property: @project.root_ancestor.id.to_s)
    end
  end

  before_action do
    push_frontend_feature_flag(:mr_collapsed_approval_rules, @project)
    push_frontend_feature_flag(:show_relevant_approval_rule_approvers, @project, default_enabled: :yaml)
  end

  around_action :allow_gitaly_ref_name_caching, only: [:index, :show, :discussions]

  after_action :log_merge_request_show, only: [:show]

  feature_category :code_review, [
                     :assign_related_issues, :bulk_update, :cancel_auto_merge,
                     :commit_change_content, :commits, :context_commits, :destroy,
                     :discussions, :edit, :index, :merge, :rebase, :remove_wip,
                     :show, :toggle_award_emoji, :toggle_subscription, :update
                   ]

  feature_category :code_testing, [
                     :test_reports, :coverage_reports, :codequality_reports,
                     :codequality_mr_diff_reports
                   ]

  feature_category :accessibility_testing, [:accessibility_reports]
  feature_category :infrastructure_as_code, [:terraform_reports]
  feature_category :continuous_integration, [:pipeline_status, :pipelines, :exposed_artifacts]

  def index
    @merge_requests = @issuables

    respond_to do |format|
      format.html
      format.json do
        render json: {
          html: view_to_html_string("projects/merge_requests/_merge_requests")
        }
      end
    end
  end

  def show
    close_merge_request_if_no_source_project

    if Feature.disabled?(:check_mergeability_async_in_widget, @project, default_enabled: :yaml)
      @merge_request.check_mergeability(async: true)
    end

    respond_to do |format|
      format.html do
        # use next to appease Rubocop
        next render('invalid') if target_branch_missing?

        preload_assignees_for_render(@merge_request)

        # Build a note object for comment form
        @note = @project.notes.new(noteable: @merge_request)

        @noteable = @merge_request
        @commits_count = @merge_request.commits_count + @merge_request.context_commits_count
        @diffs_count = get_diffs_count
        @issuable_sidebar = serializer.represent(@merge_request, serializer: 'sidebar')
        @current_user_data = UserSerializer.new(project: @project).represent(current_user, {}, MergeRequestCurrentUserEntity).to_json
        @show_whitespace_default = current_user.nil? || current_user.show_whitespace_in_diffs
        @file_by_file_default = current_user&.view_diffs_file_by_file
        @coverage_path = coverage_reports_project_merge_request_path(@project, @merge_request, format: :json) if @merge_request.has_coverage_reports?
        @update_current_user_path = expose_path(api_v4_user_preferences_path)
        @endpoint_metadata_url = endpoint_metadata_url(@project, @merge_request)

        set_pipeline_variables

        render
      end

      format.json do
        Gitlab::PollingInterval.set_header(response, interval: 10_000)

        render json: serializer.represent(@merge_request, serializer: params[:serializer])
      end

      format.patch do
        break render_404 unless @merge_request.diff_refs

        send_git_patch @project.repository, @merge_request.diff_refs
      end

      format.diff do
        break render_404 unless @merge_request.diff_refs

        send_git_diff @project.repository, @merge_request.diff_refs
      end
    end
  end

  def commits
    # Get context commits from repository
    @context_commits =
      set_commits_for_rendering(
        @merge_request.recent_context_commits
      )

    # Get commits from repository
    # or from cache if already merged
    @commits =
      set_commits_for_rendering(
        @merge_request.recent_commits.with_latest_pipeline(@merge_request.source_branch).with_markdown_cache,
        commits_count: @merge_request.commits_count
      )

    render json: { html: view_to_html_string('projects/merge_requests/_commits') }
  end

  def pipelines
    set_pipeline_variables
    @pipelines = @pipelines.page(params[:page])

    Gitlab::PollingInterval.set_header(response, interval: 10_000)

    render json: {
      pipelines: PipelineSerializer
        .new(project: @project, current_user: @current_user)
        .with_pagination(request, response)
        .represent(@pipelines),
      count: {
        all: @pipelines.count
      }
    }
  end

  def sast_reports
    reports_response(merge_request.compare_sast_reports(current_user), head_pipeline)
  end

  def secret_detection_reports
    reports_response(merge_request.compare_secret_detection_reports(current_user), head_pipeline)
  end

  def context_commits
    return render_404 unless project.context_commits_enabled?

    # Get commits from repository
    # or from cache if already merged
    commits = ContextCommitsFinder.new(project, @merge_request, { search: params[:search], limit: params[:limit], offset: params[:offset] }).execute
    render json: CommitEntity.represent(commits, { type: :full, request: merge_request })
  end

  def test_reports
    reports_response(@merge_request.compare_test_reports)
  end

  def accessibility_reports
    if @merge_request.has_accessibility_reports?
      reports_response(@merge_request.compare_accessibility_reports)
    else
      head :no_content
    end
  end

  def coverage_reports
    if @merge_request.has_coverage_reports?
      reports_response(@merge_request.find_coverage_reports)
    else
      head :no_content
    end
  end

  def codequality_mr_diff_reports
    reports_response(@merge_request.find_codequality_mr_diff_reports, head_pipeline)
  end

  def codequality_reports
    reports_response(@merge_request.compare_codequality_reports)
  end

  def terraform_reports
    reports_response(@merge_request.find_terraform_reports)
  end

  def exposed_artifacts
    if @merge_request.has_exposed_artifacts?
      reports_response(@merge_request.find_exposed_artifacts)
    else
      head :no_content
    end
  end

  def edit
    define_edit_vars
  end

  def update
    @merge_request = ::MergeRequests::UpdateService.new(project: project, current_user: current_user, params: merge_request_update_params).execute(@merge_request)

    respond_to do |format|
      format.html do
        if @merge_request.errors.present?
          define_edit_vars

          render :edit
        else
          redirect_to project_merge_request_path(@merge_request.target_project, @merge_request)
        end
      end

      format.json do
        if merge_request.errors.present?
          render json: @merge_request.errors, status: :bad_request
        else
          render json: serializer.represent(@merge_request, serializer: 'basic')
        end
      end
    end
  rescue ActiveRecord::StaleObjectError
    define_edit_vars if request.format.html?

    render_conflict_response
  end

  def remove_wip
    @merge_request = ::MergeRequests::UpdateService
      .new(project: project, current_user: current_user, params: { wip_event: 'unwip' })
      .execute(@merge_request)

    render json: serialize_widget(@merge_request)
  end

  def commit_change_content
    render partial: 'projects/merge_requests/widget/commit_change_content', layout: false
  end

  def cancel_auto_merge
    unless @merge_request.can_cancel_auto_merge?(current_user)
      return access_denied!
    end

    AutoMergeService.new(project, current_user).cancel(@merge_request)

    render json: serialize_widget(@merge_request)
  end

  def merge
    access_check_result = merge_access_check

    return access_check_result if access_check_result

    status = merge!

    if @merge_request.merge_error
      render json: { status: status, merge_error: @merge_request.merge_error }
    else
      render json: { status: status }
    end
  end

  def assign_related_issues
    result = ::MergeRequests::AssignIssuesService.new(project: project, current_user: current_user, params: { merge_request: @merge_request }).execute

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
      .represent_status(head_pipeline)
  end

  def ci_environments_status
    environments =
      if ci_environments_status_on_merge_result?
        EnvironmentStatus.for_deployed_merge_request(@merge_request, current_user)
      else
        EnvironmentStatus.for_merge_request(@merge_request, current_user)
      end

    render json: EnvironmentStatusSerializer.new(current_user: current_user).represent(environments)
  end

  def rebase
    @merge_request.rebase_async(current_user.id)

    head :ok
  rescue MergeRequest::RebaseLockTimeout => e
    render json: { merge_error: e.message }, status: :conflict
  end

  def discussions
    merge_request.discussions_diffs.load_highlight

    super
  end

  def export_csv
    IssuableExportCsvWorker.perform_async(:merge_request, current_user.id, project.id, finder_options.to_h) # rubocop:disable CodeReuse/Worker

    index_path = project_merge_requests_path(project)
    message = _('Your CSV export has started. It will be emailed to %{email} when complete.') % { email: current_user.notification_email }
    redirect_to(index_path, notice: message)
  end

  protected

  alias_method :subscribable_resource, :merge_request
  alias_method :issuable, :merge_request
  alias_method :awardable, :merge_request

  def sorting_field
    MergeRequest::SORTING_PREFERENCE_FIELD
  end

  def merge_params
    params.permit(merge_params_attributes)
  end

  def merge_params_attributes
    MergeRequest::KNOWN_MERGE_PARAMS
  end

  def auto_merge_requested?
    # Support params[:merge_when_pipeline_succeeds] during the transition period
    params[:auto_merge_strategy].present? || params[:merge_when_pipeline_succeeds].present?
  end

  private

  def get_diffs_count
    if show_only_context_commits?
      @merge_request.context_commits_diff.raw_diffs.size
    else
      @merge_request.diff_size
    end
  end

  def merge_request_update_params
    merge_request_params.merge!(params.permit(:merge_request_diff_head_sha))
  end

  def head_pipeline
    strong_memoize(:head_pipeline) do
      pipeline = @merge_request.head_pipeline
      pipeline if can?(current_user, :read_pipeline, pipeline)
    end
  end

  def ci_environments_status_on_merge_result?
    params[:environment_target] == 'merge_commit'
  end

  def target_branch_missing?
    @merge_request.has_no_commits? && !@merge_request.target_branch_exists?
  end

  def merge!
    # Disable the CI check if auto_merge_strategy is specified since we have
    # to wait until CI completes to know
    unless @merge_request.mergeable?(skip_ci_check: auto_merge_requested?)
      return :failed
    end

    merge_service = ::MergeRequests::MergeService.new(project: @project, current_user: current_user, params: merge_params)

    unless merge_service.hooks_validation_pass?(@merge_request)
      return :hook_validation_error
    end

    return :sha_mismatch if params[:sha] != @merge_request.diff_head_sha

    @merge_request.update(merge_error: nil, squash: params.fetch(:squash, false))

    if auto_merge_requested?
      if merge_request.auto_merge_enabled?
        # TODO: We should have a dedicated endpoint for updating merge params.
        #       See https://gitlab.com/gitlab-org/gitlab-foss/issues/63130.
        AutoMergeService.new(project, current_user, merge_params).update(merge_request)
      else
        AutoMergeService.new(project, current_user, merge_params)
          .execute(merge_request,
                   params[:auto_merge_strategy] || AutoMergeService::STRATEGY_MERGE_WHEN_PIPELINE_SUCCEEDS)
      end
    else
      @merge_request.merge_async(current_user.id, merge_params)

      :success
    end
  end

  def serialize_widget(merge_request)
    cached_data = serializer.represent(merge_request, serializer: 'poll_cached_widget')
    widget_data = serializer.represent(merge_request, serializer: 'poll_widget')
    cached_data.merge!(widget_data)
  end

  def serializer
    @serializer ||= MergeRequestSerializer.new(current_user: current_user, project: merge_request.project)
  end

  def define_edit_vars
    @source_project = @merge_request.source_project
    @target_project = @merge_request.target_project
    @noteable = @merge_request

    # FIXME: We have to assign a presenter to another instance variable
    # due to class_name checks being made with issuable classes
    @mr_presenter = @merge_request.present(current_user: current_user)
  end

  def finder_type
    MergeRequestsFinder
  end

  def check_user_can_push_to_source_branch!
    return access_denied! unless @merge_request.source_branch_exists?

    access_check = ::Gitlab::UserAccess
      .new(current_user, container: @merge_request.source_project)
      .can_push_to_branch?(@merge_request.source_branch)

    access_denied! unless access_check
  end

  def merge_access_check
    access_denied! unless @merge_request.can_be_merged_by?(current_user)
  end

  def disable_query_limiting
    # Also see https://gitlab.com/gitlab-org/gitlab/-/issues/20827
    Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/20824')
  end

  def reports_response(report_comparison, pipeline = nil)
    if pipeline&.active?
      ::Gitlab::PollingInterval.set_header(response, interval: 3000)

      render json: '', status: :no_content && return
    end

    case report_comparison[:status]
    when :parsing
      ::Gitlab::PollingInterval.set_header(response, interval: 3000)

      render json: '', status: :no_content
    when :parsed
      render json: report_comparison[:data].to_json, status: :ok
    when :error
      render json: { status_reason: report_comparison[:status_reason] }, status: :bad_request
    else
      raise "Failed to build comparison response as comparison yielded unknown status '#{report_comparison[:status]}'"
    end
  end

  def log_merge_request_show
    return unless current_user && @merge_request

    ::Gitlab::Search::RecentMergeRequests.new(user: current_user).log_view(@merge_request)
  end

  def authorize_read_actual_head_pipeline!
    return render_404 unless can?(current_user, :read_build, merge_request.actual_head_pipeline)
  end

  def endpoint_metadata_url(project, merge_request)
    params = request.query_parameters
    params[:view] = "inline"

    if Feature.enabled?(:default_merge_ref_for_diffs, project, default_enabled: :yaml)
      params = params.merge(diff_head: true)
    end

    diffs_metadata_project_json_merge_request_path(project, merge_request, 'json', params)
  end
end

Projects::MergeRequestsController.prepend_mod_with('Projects::MergeRequestsController')
