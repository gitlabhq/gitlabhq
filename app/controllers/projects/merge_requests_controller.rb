# frozen_string_literal: true

class Projects::MergeRequestsController < Projects::MergeRequests::ApplicationController
  include ToggleSubscriptionAction
  include IssuableActions
  include RendersCommits
  include RendersAssignees
  include ToggleAwardEmoji
  include IssuableCollections
  include RecordUserLastActivity
  include SourcegraphDecorator
  include DiffHelper
  include Gitlab::Cache::Helpers
  include MergeRequestsHelper
  include ParseCommitDate
  include DiffsStreamResource

  prepend_before_action(only: [:index]) { authenticate_sessionless_user!(:rss) }
  skip_before_action :merge_request, only: [:index, :bulk_update, :export_csv]
  before_action :apply_diff_view_cookie!, only: [:show, :diffs, :rapid_diffs]
  before_action :disable_query_limiting, only: [:assign_related_issues, :update]
  before_action :authorize_update_issuable!, only: [:close, :edit, :update, :remove_wip, :sort]
  before_action :authorize_read_diff_head_pipeline!, only: [
    :test_reports,
    :exposed_artifacts,
    :coverage_reports,
    :terraform_reports,
    :accessibility_reports,
    :codequality_reports,
    :codequality_mr_diff_reports
  ]
  before_action :set_issuables_index, only: [:index]
  before_action :check_search_rate_limit!, only: [:index], if: -> { params[:search].present? }
  before_action :authenticate_user!, only: [:assign_related_issues]
  before_action :check_user_can_push_to_source_branch!, only: [:rebase]

  before_action only: :index do
    push_frontend_feature_flag(:mr_approved_filter, type: :ops)
  end

  before_action only: [:show, :diffs, :rapid_diffs, :reports] do
    push_frontend_feature_flag(:mr_experience_survey, project)
    push_frontend_feature_flag(:mr_pipelines_graphql, project)
    push_frontend_feature_flag(:notifications_todos_buttons, current_user)
    push_frontend_feature_flag(:mr_show_reports_immediately, project)
  end

  around_action :allow_gitaly_ref_name_caching, only: [:index, :show, :diffs, :rapid_diffs, :discussions]

  after_action :log_merge_request_show, only: [:show, :diffs, :rapid_diffs]

  feature_category :code_review_workflow, [
    :assign_related_issues, :bulk_update, :cancel_auto_merge,
    :commit_change_content, :commits, :context_commits, :destroy,
    :discussions, :edit, :index, :merge, :rebase, :remove_wip,
    :show, :diffs, :rapid_diffs, :toggle_award_emoji, :toggle_subscription, :update
  ]

  feature_category :code_testing, [:test_reports, :coverage_reports]
  feature_category :code_quality, [:codequality_reports, :codequality_mr_diff_reports]
  feature_category :code_testing, [:accessibility_reports]
  feature_category :infrastructure_as_code, [:terraform_reports]
  feature_category :continuous_integration, [:pipeline_status, :pipelines, :exposed_artifacts]

  urgency :high, [:export_csv]
  urgency :low, [
    :index,
    :show,
    :diffs,
    :rapid_diffs,
    :commits,
    :bulk_update,
    :edit,
    :update,
    :cancel_auto_merge,
    :merge,
    :ci_environments_status,
    :destroy,
    :rebase,
    :discussions,
    :pipelines,
    :coverage_reports,
    :test_reports,
    :codequality_mr_diff_reports,
    :codequality_reports,
    :terraform_reports
  ]
  urgency :low, [:pipeline_status, :pipelines, :exposed_artifacts]

  def index
    @merge_requests = @issuables

    respond_to do |format|
      format.html
      format.atom { render layout: 'xml' }
    end
  end

  def show
    show_merge_request
  end

  def diffs
    show_merge_request
  end

  def rapid_diffs
    return render_404 unless ::Feature.enabled?(:rapid_diffs, current_user, type: :wip)

    streaming_offset = 5
    @reload_stream_url = diffs_stream_url(@merge_request)
    @stream_url = diffs_stream_url(@merge_request, streaming_offset, diff_view)
    @diffs_slice = @merge_request.first_diffs_slice(streaming_offset)

    show_merge_request
  end

  def commits
    # Get context commits from repository
    @context_commits =
      set_commits_for_rendering(
        @merge_request.recent_context_commits
      )

    per_page = [
      (params[:per_page] || MergeRequestDiff::COMMITS_SAFE_SIZE).to_i,
      MergeRequestDiff::COMMITS_SAFE_SIZE
    ].min
    recent_commits = @merge_request
      .recent_commits(load_from_gitaly: true, limit: per_page, page: params[:page])
      .with_latest_pipeline(@merge_request.source_branch)
      .with_markdown_cache
    @next_page = recent_commits.next_page
    @commits = set_commits_for_rendering(
      recent_commits,
      commits_count: @merge_request.commits_count
    )

    commits_count = if @merge_request.preparing?
                      '-'
                    else
                      @merge_request.commits_count + @merge_request.context_commits_count
                    end

    render json: {
      html: view_to_html_string('projects/merge_requests/_commits'),
      next_page: @next_page,
      count: commits_count
    }
  end

  def pipelines
    set_pipeline_variables
    @pipelines = @pipelines.page(params[:page])

    Gitlab::PollingInterval.set_header(response, interval: 10_000)

    render json: {
      pipelines: PipelineSerializer
        .new(project: @project, current_user: @current_user)
        .with_pagination(request, response)
        .represent(
          @pipelines,
          disable_coverage: true,
          disable_failed_builds: true,
          disable_manual_and_scheduled_actions: true,
          preload: true,
          preload_statuses: false,
          preload_downstream_statuses: false
        ),
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
    # Get commits from repository
    # or from cache if already merged
    commits = ContextCommitsFinder.new(project, @merge_request, {
      search: params[:search],
      author: params[:author],
      committed_before: convert_date_to_epoch(params[:committed_before]),
      committed_after: convert_date_to_epoch(params[:committed_after]),
      limit: params[:limit]
    }).execute
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

  # documented in doc/development/rails_endpoints/index.md
  def codequality_mr_diff_reports
    reports_response(@merge_request.find_codequality_mr_diff_reports, head_pipeline)
  end

  # documented in doc/development/rails_endpoints/index.md
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
    @merge_request = ::MergeRequests::UpdateService
      .new(project: project, current_user: current_user, params: merge_request_update_params)
      .execute(@merge_request)

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
          render json: serializer.represent(@merge_request, serializer: params[:serializer] || 'basic')
        end
      end
    end
  rescue ActiveRecord::StaleObjectError
    define_edit_vars if request.format.html?

    render_conflict_response
  end

  def remove_wip
    @merge_request = ::MergeRequests::UpdateService
      .new(project: project, current_user: current_user, params: { wip_event: 'ready' })
      .execute(@merge_request)

    render json: serialize_widget(@merge_request)
  end

  def commit_change_content
    render partial: 'projects/merge_requests/widget/commit_change_content', layout: false
  end

  def cancel_auto_merge
    return access_denied! unless @merge_request.can_cancel_auto_merge?(current_user)

    AutoMergeService.new(project, current_user).cancel(@merge_request)

    render json: serialize_widget(@merge_request)
  end

  def merge
    access_check_result = merge_access_check

    return access_check_result if access_check_result

    status = merge!

    Gitlab::ApplicationContext.push(merge_action_status: status.to_s)

    if @merge_request.merge_error
      render json: { status: status, merge_error: @merge_request.merge_error }
    else
      render json: { status: status }
    end
  end

  def assign_related_issues
    result = ::MergeRequests::AssignIssuesService
      .new(project: project, current_user: current_user, params: { merge_request: @merge_request })
      .execute

    case result[:count]
    when 0
      flash[:alert] = _("Failed to assign you issues related to the merge request.")
    else
      flash[:notice] = n_("An issue has been assigned to you.", "%d issues have been assigned to you.", result[:count])
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
    @merge_request
      .rebase_async(current_user.id, skip_ci: Gitlab::Utils.to_boolean(merge_params[:skip_ci], default: false))

    head :ok
  rescue MergeRequest::RebaseLockTimeout => e
    render json: { merge_error: e.message }, status: :conflict
  end

  def discussions
    super do |discussion_notes|
      note_ids = discussion_notes.flat_map { |x| x.notes.collect(&:id) }
      merge_request.discussions_diffs.load_highlight(diff_note_ids: note_ids)
    end
  end

  def export_csv
    IssuableExportCsvWorker.perform_async(:merge_request, current_user.id, project.id, finder_options.to_h) # rubocop:disable CodeReuse/Worker

    index_path = project_merge_requests_path(project)
    message = format(_('Your CSV export has started. It will be emailed to %{email} when complete.'),
      email: current_user.notification_email_or_default)
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

  def set_issuables_index
    return if ::Feature.enabled?(:vue_merge_request_list, current_user) && request.format.html?

    super
  end

  def show_merge_request
    close_merge_request_if_no_source_project
    @merge_request.check_mergeability(async: true)

    # We need to handle the exception that the auto merge was missed
    # For example, the approval group was changed and now the approvals are passing
    if Feature.enabled?(:process_auto_merge_on_load, @merge_request.project) &&
        @merge_request.auto_merge_enabled? &&
        @merge_request.mergeability_checks_pass?
      Gitlab::EventStore.publish(
        MergeRequests::MergeableEvent.new(
          data: { merge_request_id: @merge_request.id }
        )
      )
    end

    respond_to do |format|
      format.html do
        # use next to appease Rubocop
        next render('invalid') if target_branch_missing?

        render_html_page
      end

      format.json do
        Gitlab::PollingInterval.set_header(response, interval: 10_000)

        if params[:serializer] == 'sidebar_extras'
          cache_context = [
            params[:serializer],
            current_user&.cache_key,
            @merge_request.merge_request_assignees.map(&:cache_key),
            @merge_request.merge_request_reviewers.map(&:cache_key)
          ]

          render_cached(
            @merge_request,
            with: serializer,
            cache_context: ->(_) { [Digest::SHA256.hexdigest(cache_context.to_s)] },
            serializer: params[:serializer]
          )
        else
          render json: serializer.represent(@merge_request, serializer: params[:serializer])
        end
      end

      format.patch do
        next render_404 unless @merge_request.diff_refs

        send_git_patch @project.repository, @merge_request.diff_refs
      end

      format.diff do
        next render_404 unless @merge_request.diff_refs

        send_git_diff @project.repository, @merge_request.diff_refs
      end
    end
  end

  def render_html_page
    preload_assignees_for_render(@merge_request)

    # Build a note object for comment form
    @note = @project.notes.new(noteable: @merge_request)

    @noteable = @merge_request
    @commits_count = @merge_request.commits_count + @merge_request.context_commits_count
    @diffs_count = get_diffs_count
    @issuable_sidebar = serializer.represent(@merge_request, serializer: 'sidebar')
    @current_user_data = Gitlab::Json
      .dump(UserSerializer.new(project: @project)
      .represent(current_user, {}, MergeRequestCurrentUserEntity))
    @show_whitespace_default = current_user.nil? || current_user.show_whitespace_in_diffs
    @file_by_file_default = current_user&.view_diffs_file_by_file
    if @merge_request.has_coverage_reports?
      @coverage_path = coverage_reports_project_merge_request_path(@project, @merge_request, format: :json)
    end

    @update_current_user_path = expose_path(api_v4_user_preferences_path)
    @endpoint_metadata_url = endpoint_metadata_url(@project, @merge_request)
    @endpoint_diff_batch_url = endpoint_diff_batch_url(@project, @merge_request)
    @linked_file_url = linked_file_url(@project, @merge_request) if params[:file]

    if merge_request.diffs_batch_cache_with_max_age?
      @diffs_batch_cache_key = @merge_request.merge_head_diff&.patch_id_sha
    end

    set_pipeline_variables

    @number_of_pipelines = @pipelines.size

    render
  end

  def get_diffs_count
    return @commit.raw_diffs.size if commit
    return @merge_request.context_commits_diff.raw_diffs.size if show_only_context_commits?
    return @merge_request.merge_request_diffs.find_by_id(params[:diff_id])&.size if params[:diff_id]
    return @merge_request.merge_head_diff.size if @merge_request.diffable_merge_ref? && params[:start_sha].blank?

    @merge_request.diff_size
  end

  def merge_request_update_params
    merge_request_params.merge!(params.permit(:merge_request_diff_head_sha))
  end

  def head_pipeline
    pipeline = @merge_request.head_pipeline
    pipeline if can?(current_user, :read_pipeline, pipeline)
  end
  strong_memoize_attr :head_pipeline

  def ci_environments_status_on_merge_result?
    params[:environment_target] == 'merge_commit'
  end

  def target_branch_missing?
    @merge_request.has_no_commits? && !@merge_request.target_branch_exists?
  end

  def merge!
    # Disable the CI check if auto_merge_strategy is specified since we have
    # to wait until CI completes to know
    skipped_checks = @merge_request.skipped_mergeable_checks(
      auto_merge_requested: auto_merge_requested?,
      auto_merge_strategy: params[:auto_merge_strategy]
    )

    return :failed unless @merge_request.mergeable?(**skipped_checks)

    squashing = params.fetch(:squash, false)
    merge_service = ::MergeRequests::MergeService
      .new(project: @project, current_user: current_user, params: merge_params)

    unless merge_service.hooks_validation_pass?(@merge_request, validate_squash_message: squashing)
      return :hook_validation_error
    end

    return :sha_mismatch if params[:sha] != @merge_request.diff_head_sha

    @merge_request.update(merge_error: nil, squash: squashing)

    if auto_merge_requested?
      if merge_request.auto_merge_enabled?
        # TODO: We should have a dedicated endpoint for updating merge params.
        #       See https://gitlab.com/gitlab-org/gitlab-foss/issues/63130.
        AutoMergeService.new(project, current_user, merge_params).update(merge_request)
      else
        AutoMergeService.new(project, current_user, merge_params)
          .execute(
            merge_request,
            params[:auto_merge_strategy] || merge_request.default_auto_merge_strategy
          )
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
    result = MergeRequests::RebaseService
      .new(project: @merge_request.source_project, current_user: current_user)
      .validate(@merge_request)

    return if result.success?

    render json: { merge_error: result.message }, status: :forbidden
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
      render json: Gitlab::Json.dump(report_comparison[:data]), status: :ok
    when :error
      render json: {
               errors: [report_comparison[:status_reason]],
               status_reason: report_comparison[:status_reason]
             },
        status: :bad_request
    else
      raise "Failed to build comparison response as comparison yielded unknown status '#{report_comparison[:status]}'"
    end
  end

  def log_merge_request_show
    return unless current_user && @merge_request

    ::Gitlab::Search::RecentMergeRequests.new(user: current_user).log_view(@merge_request)
  end

  def authorize_read_diff_head_pipeline!
    render_404 unless can?(current_user, :read_build, merge_request.diff_head_pipeline)
  end

  def show_whitespace
    current_user&.show_whitespace_in_diffs ? '0' : '1'
  end

  def endpoint_metadata_url(project, merge_request)
    params = request.query_parameters.merge(view: 'inline', diff_head: true, w: show_whitespace)

    diffs_metadata_project_json_merge_request_path(project, merge_request, 'json', params)
  end

  def endpoint_diff_batch_url(project, merge_request)
    per_page = current_user&.view_diffs_file_by_file ? '1' : DIFF_BATCH_ENDPOINT_PER_PAGE.to_s
    params = request
      .query_parameters
      .merge(view: 'inline', diff_head: true, w: show_whitespace, page: '0', per_page: per_page)
    params[:ck] = merge_request.merge_head_diff&.patch_id_sha if merge_request.diffs_batch_cache_with_max_age?

    diffs_batch_project_json_merge_request_path(project, merge_request, 'json', params)
  end

  def linked_file_url(project, merge_request)
    diff_by_file_hash_namespace_project_merge_request_path(
      format: 'json',
      id: merge_request.iid,
      namespace_id: project&.namespace.to_param,
      project_id: project&.path,
      file_hash: params[:file],
      diff_head: true
    )
  end

  def append_info_to_payload(payload)
    super

    return unless action_name == 'diffs' && @merge_request&.merge_request_diff.present?

    payload[:metadata] ||= {}
    payload[:metadata]['meta.diffs_files_count'] = @merge_request.merge_request_diff.files_count
  end

  def diffs_stream_resource_url(merge_request, offset, diff_view)
    diffs_stream_namespace_project_merge_request_path(
      id: merge_request.iid,
      project_id: merge_request.project.to_param,
      namespace_id: merge_request.project.namespace.to_param,
      offset: offset,
      view: diff_view
    )
  end
end

Projects::MergeRequestsController.prepend_mod_with('Projects::MergeRequestsController')
