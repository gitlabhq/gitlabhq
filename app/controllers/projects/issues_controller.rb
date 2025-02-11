# frozen_string_literal: true

class Projects::IssuesController < Projects::ApplicationController
  include ToggleSubscriptionAction
  include IssuableActions
  include ToggleAwardEmoji
  include IssuableCollections
  include IssuesCalendar
  include RecordUserLastActivity

  ISSUES_EXCEPT_ACTIONS = %i[index calendar new create bulk_update import_csv export_csv service_desk can_create_branch].freeze
  SET_ISSUABLES_INDEX_ONLY_ACTIONS = %i[index calendar service_desk].freeze

  prepend_before_action(only: [:index]) { authenticate_sessionless_user!(:rss) }
  prepend_before_action(only: [:calendar]) { authenticate_sessionless_user!(:ics) }
  prepend_before_action :authenticate_user!, only: [:new, :export_csv]
  prepend_before_action :store_uri, only: [:new, :show, :designs]

  before_action :disable_query_limiting, only: [:create_merge_request, :move, :bulk_update]
  before_action :check_issues_available!
  before_action :issue, unless: ->(c) { ISSUES_EXCEPT_ACTIONS.include?(c.action_name.to_sym) }
  before_action :redirect_if_work_item, unless: ->(c) { work_item_redirect_except_actions.include?(c.action_name.to_sym) }
  before_action :require_incident_for_incident_routes, only: :show

  after_action :log_issue_show, only: :show

  before_action :set_issuables_index, if: ->(c) {
    SET_ISSUABLES_INDEX_ONLY_ACTIONS.include?(c.action_name.to_sym) && !index_html_request?
  }
  before_action :check_search_rate_limit!, if: ->(c) {
    SET_ISSUABLES_INDEX_ONLY_ACTIONS.include?(c.action_name.to_sym) && !index_html_request? && params[:search].present?
  }

  # Allow write(create) issue
  before_action :authorize_create_issue!, only: [:new, :create]

  # Allow modify issue
  before_action :authorize_update_issuable!, only: [:edit, :update, :move, :reorder]

  # Allow create a new branch and empty WIP merge request from current issue
  before_action :authorize_create_merge_request_from!, only: [:create_merge_request]

  before_action :authorize_import_issues!, only: [:import_csv]
  before_action :authorize_read_code!, only: [:related_branches]

  before_action do
    push_frontend_feature_flag(:preserve_markdown, project)
    push_frontend_feature_flag(:issues_grid_view)
    push_frontend_feature_flag(:service_desk_ticket)
    push_frontend_feature_flag(:issues_list_drawer, project)
    push_frontend_feature_flag(:notifications_todos_buttons, current_user)
    push_force_frontend_feature_flag(:glql_integration, project&.glql_integration_feature_flag_enabled?)
    push_force_frontend_feature_flag(:continue_indented_text, project&.continue_indented_text_feature_flag_enabled?)
    push_force_frontend_feature_flag(:work_items_beta, project&.work_items_beta_feature_flag_enabled?)
    push_force_frontend_feature_flag(:work_items_alpha, project&.work_items_alpha_feature_flag_enabled?)
    push_frontend_feature_flag(:work_item_description_templates, project&.group)
  end

  before_action only: [:index, :show] do
    push_force_frontend_feature_flag(:work_items, project&.work_items_feature_flag_enabled?)
  end

  before_action only: [:index, :service_desk] do
    push_frontend_feature_flag(:frontend_caching, project&.group)
  end

  before_action only: :show do
    push_frontend_feature_flag(:epic_widget_edit_confirmation, project)
    push_frontend_feature_flag(:work_items_view_preference, current_user)
  end

  around_action :allow_gitaly_ref_name_caching, only: [:discussions]

  respond_to :html

  feature_category :team_planning, [
    :index, :calendar, :show, :new, :create, :edit, :update,
    :destroy, :move, :reorder, :designs, :toggle_subscription,
    :discussions, :bulk_update, :realtime_changes,
    :toggle_award_emoji, :mark_as_spam, :related_branches,
    :can_create_branch, :create_merge_request
  ]
  urgency :low, [
    :index, :calendar, :show, :new, :create, :edit, :update,
    :destroy, :move, :reorder, :designs, :toggle_subscription,
    :discussions, :bulk_update, :realtime_changes,
    :toggle_award_emoji, :mark_as_spam, :related_branches,
    :can_create_branch, :create_merge_request
  ]

  feature_category :service_desk, [:service_desk]
  urgency :low, [:service_desk]
  feature_category :importers, [:import_csv, :export_csv]
  urgency :low, [:import_csv, :export_csv]

  attr_accessor :vulnerability_id

  def index
    if index_html_request?
      set_sort_order
    else
      @issues = @issuables
    end

    respond_to do |format|
      format.html
      format.atom { render layout: 'xml' }
    end
  end

  def calendar
    render_issues_calendar(@issuables)
  end

  def new
    params[:issue] ||= ActionController::Parameters.new(
      assignee_ids: ""
    )
    build_params = issue_params.merge(
      merge_request_to_resolve_discussions_of: params[:merge_request_to_resolve_discussions_of],
      discussion_to_resolve: params[:discussion_to_resolve],
      observability_links: { metrics: params[:observability_metric_details], logs: params[:observability_log_details], tracing: params[:observability_trace_details] },
      confidential: !!Gitlab::Utils.to_boolean(issue_params[:confidential])
    )
    service = ::Issues::BuildService.new(container: project, current_user: current_user, params: build_params)

    @issue = @noteable = service.execute

    @add_related_issue = add_related_issue

    @merge_request_to_resolve_discussions_of = service.merge_request_to_resolve_discussions_of

    if params[:discussion_to_resolve]
      Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter.track_resolve_thread_in_issue_action(user: current_user)
      @discussion_to_resolve = service.discussions_to_resolve.first
    end

    respond_with(@issue)
  end

  def show
    return super unless show_work_item? && request.format.html?

    @right_sidebar = false
    @work_item = issue.becomes(::WorkItem) # rubocop:disable Cop/AvoidBecomes -- We need the instance to be a work item

    render 'projects/work_items/show'
  end

  alias_method :designs, :show

  def edit
    respond_with(@issue)
  end

  def create
    create_params = issue_params.merge(
      add_related_issue: add_related_issue,
      merge_request_to_resolve_discussions_of: params[:merge_request_to_resolve_discussions_of],
      observability_links: params[:observability_links],
      discussion_to_resolve: params[:discussion_to_resolve]
    )

    service = ::Issues::CreateService.new(container: project, current_user: current_user, params: create_params)
    result = service.execute

    # Only irrecoverable errors such as unauthorized user won't contain an issue in the response
    render_by_create_result_error(result) && return if result.error? && result[:issue].blank?

    @issue = result[:issue]

    if result.success?
      create_vulnerability_issue_feedback(@issue)

      if service.discussions_to_resolve.count(&:resolved?) > 0
        flash[:notice] = if service.discussion_to_resolve_id
                           _("Resolved 1 discussion.")
                         else
                           _("Resolved all discussions.")
                         end
      end

      redirect_to project_issue_path(@project, @issue)
    else
      # NOTE: this CAPTCHA support method is indirectly included via IssuableActions
      with_captcha_check_html_format(spammable: spammable) { render :new }
    end
  end

  def move
    params.require(:move_to_project_id)

    if params[:move_to_project_id].to_i > 0
      new_project = Project.find(params[:move_to_project_id])
      return render_404 unless issue.can_move?(current_user, new_project)

      @issue = ::Issues::MoveService.new(container: project, current_user: current_user).execute(issue, new_project)
    end

    respond_to do |format|
      format.json do
        render_issue_json
      end
    end

  rescue ActiveRecord::StaleObjectError
    render_conflict_response
  end

  def reorder
    service = ::Issues::ReorderService.new(container: project, current_user: current_user, params: reorder_params)

    if service.execute(issue)
      head :ok
    else
      head :unprocessable_entity
    end
  end

  def related_branches
    @related_branches = ::Issues::RelatedBranchesService
      .new(container: project, current_user: current_user)
      .execute(issue)

    respond_to do |format|
      format.json do
        render json: {
          html: view_to_html_string('projects/issues/_related_branches')
        }
      end
    end
  end

  def can_create_branch
    can_create = current_user &&
      can?(current_user, :push_code, @project) &&
      issue.can_be_worked_on?

    respond_to do |format|
      format.json do
        render json: { can_create_branch: can_create, suggested_branch_name: issue.suggested_branch_name }
      end
    end
  end

  def create_merge_request
    create_params = params.slice(:branch_name, :ref).merge(issue_iid: issue.iid)
    create_params[:target_project_id] = params[:target_project_id]
    result = ::MergeRequests::CreateFromIssueService.new(project: project, current_user: current_user, mr_params: create_params).execute

    if result[:status] == :success
      render json: MergeRequestCreateSerializer.new.represent(result[:merge_request])
    else
      render json: result[:message], status: :unprocessable_entity
    end
  end

  def export_csv
    IssuableExportCsvWorker.perform_async(:issue, current_user.id, project.id, finder_options.to_h) # rubocop:disable CodeReuse/Worker

    index_path = project_issues_path(project)
    message = _('Your CSV export has started. It will be emailed to %{email} when complete.') % { email: current_user.notification_email_or_default }
    redirect_to(index_path, notice: message)
  end

  def import_csv
    result = Issues::PrepareImportCsvService.new(project, current_user, file: params[:file]).execute

    if result.success?
      flash[:notice] = result.message
    else
      flash[:alert] = result.message
    end

    redirect_to project_issues_path(project)
  end

  def service_desk
    @issues = @issuables
  end

  def discussions
    Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/425834')

    super
  end

  protected

  def index_html_request?
    action_name.to_sym == :index && html_request?
  end

  def sorting_field
    Issue::SORTING_PREFERENCE_FIELD
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def issue
    return @issue if defined?(@issue)

    # The Sortable default scope causes performance issues when used with find_by
    @issuable = @noteable = @issue ||= @project.issues.inc_relations_for_view.iid_in(params[:id]).without_order.take!
    @note = @project.notes.new(noteable: @issuable)

    return render_404 unless can?(current_user, :read_issue, @issue)

    @issue
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def log_issue_show
    return unless current_user && @issue

    ::Gitlab::Search::RecentIssues.new(user: current_user).log_view(@issue)
  end

  alias_method :subscribable_resource, :issue
  alias_method :issuable, :issue
  alias_method :awardable, :issue
  alias_method :spammable, :issue

  def spammable_path
    project_issue_path(@project, @issue)
  end

  def authorize_create_merge_request!
    render_404 unless can?(current_user, :push_code, @project) && @issue.can_be_worked_on?
  end

  def render_issue_json
    if @issue.valid?
      render json: serializer.represent(@issue)
    else
      render json: { errors: @issue.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def issue_params
    params[:issue][:issue_type] ||= params[:issue_type] if params[:issue_type].present?
    all_params = params.require(:issue).permit(
      *issue_params_attributes,
      sentry_issue_attributes: [:sentry_issue_identifier]
    )

    clean_params(all_params)
  end

  def issue_params_attributes
    %i[
      title
      assignee_id
      position
      description
      confidential
      milestone_id
      due_date
      state_event
      task_num
      lock_version
      discussion_locked
      issue_type
    ] + [{ label_ids: [], assignee_ids: [], update_task: [:index, :checked, :line_number, :line_source] }]
  end

  def reorder_params
    params.permit(:move_before_id, :move_after_id)
  end

  def store_uri
    store_location_for :user, request.fullpath if request.get? && request.format.html?
  end

  def serializer
    IssueSerializer.new(current_user: current_user, project: issue.project)
  end

  def update_service
    ::Issues::UpdateService.new(
      container: project,
      current_user: current_user,
      params: issue_params,
      perform_spam_check: true)
  end

  def finder_type
    IssuesFinder
  end

  def disable_query_limiting
    # Also see the following issues:
    #
    # 1. https://gitlab.com/gitlab-org/gitlab/-/issues/20815
    # 2. https://gitlab.com/gitlab-org/gitlab/-/issues/20816
    # 3. https://gitlab.com/gitlab-org/gitlab/-/issues/21068
    Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/20814')
  end

  private

  def show_work_item?
    # Service Desk issues and incidents should not use the work item view
    !issue.from_service_desk? &&
      !issue.work_item_type&.incident? &&
      Feature.enabled?(:work_items_view_preference, current_user) &&
      current_user&.user_preference&.use_work_items_view
  end

  def work_item_redirect_except_actions
    ISSUES_EXCEPT_ACTIONS
  end

  def render_by_create_result_error(result)
    Gitlab::AppLogger.warn(
      message: 'Cannot create issue',
      errors: result.errors,
      http_status: result.http_status
    )
    error_method_name = "render_#{result.http_status}".to_sym

    if respond_to?(error_method_name, true)
      send(error_method_name) # rubocop:disable GitlabSecurity/PublicSend
    else
      render_404
    end
  end

  def clean_params(all_params)
    issue_type = all_params[:issue_type].to_s
    all_params.delete(:issue_type) unless WorkItems::Type.allowed_types_for_issues.include?(issue_type)

    all_params
  end

  def finder_options
    options = super

    options[:issue_types] = Issue::TYPES_FOR_LIST

    if service_desk?
      options.reject! { |key| key == 'author_username' || key == 'author_id' }
      options[:author_id] = Users::Internal.support_bot
    end

    options
  end

  def service_desk?
    action_name == 'service_desk'
  end

  def add_related_issue
    add_related_issue = project.issues.find_by_iid(params[:add_related_issue])
    add_related_issue if Ability.allowed?(current_user, :read_issue, add_related_issue)
  end

  # Overridden in EE
  def create_vulnerability_issue_feedback(issue); end

  def redirect_if_work_item
    return unless use_work_items_path?(issue) && !show_work_item?

    redirect_to project_work_item_path(project, issue.iid, params: request.query_parameters)
  end

  def require_incident_for_incident_routes
    return unless params[:incident_tab].present?
    return if issue.work_item_type&.incident?

    # Redirect instead of 404 to gracefully handle
    # issue type changes
    redirect_to project_issue_path(project, issue)
  end
end

Projects::IssuesController.prepend_mod_with('Projects::IssuesController')
