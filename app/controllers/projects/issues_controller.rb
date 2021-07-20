# frozen_string_literal: true

class Projects::IssuesController < Projects::ApplicationController
  include RendersNotes
  include ToggleSubscriptionAction
  include IssuableActions
  include ToggleAwardEmoji
  include IssuableCollections
  include IssuesCalendar
  include SpammableActions
  include RecordUserLastActivity

  ISSUES_EXCEPT_ACTIONS = %i[index calendar new create bulk_update import_csv export_csv service_desk].freeze
  SET_ISSUEABLES_INDEX_ONLY_ACTIONS = %i[index calendar service_desk].freeze

  prepend_before_action(only: [:index]) { authenticate_sessionless_user!(:rss) }
  prepend_before_action(only: [:calendar]) { authenticate_sessionless_user!(:ics) }
  prepend_before_action :authenticate_user!, only: [:new, :export_csv]
  prepend_before_action :store_uri, only: [:new, :show, :designs]

  before_action :disable_query_limiting, only: [:create_merge_request, :move, :bulk_update]
  before_action :check_issues_available!
  before_action :issue, unless: ->(c) { ISSUES_EXCEPT_ACTIONS.include?(c.action_name.to_sym) }
  after_action :log_issue_show, unless: ->(c) { ISSUES_EXCEPT_ACTIONS.include?(c.action_name.to_sym) }

  before_action :set_issuables_index, if: ->(c) { SET_ISSUEABLES_INDEX_ONLY_ACTIONS.include?(c.action_name.to_sym) }

  # Allow write(create) issue
  before_action :authorize_create_issue!, only: [:new, :create]

  # Allow modify issue
  before_action :authorize_update_issuable!, only: [:edit, :update, :move, :reorder]

  # Allow create a new branch and empty WIP merge request from current issue
  before_action :authorize_create_merge_request_from!, only: [:create_merge_request]

  before_action :authorize_import_issues!, only: [:import_csv]
  before_action :authorize_download_code!, only: [:related_branches]

  # Limit the amount of issues created per minute
  before_action :create_rate_limit, only: [:create]

  before_action do
    push_frontend_feature_flag(:tribute_autocomplete, @project)
    push_frontend_feature_flag(:vue_issuables_list, project)
    push_frontend_feature_flag(:usage_data_design_action, project, default_enabled: true)
    push_frontend_feature_flag(:improved_emoji_picker, project, default_enabled: :yaml)
    push_frontend_feature_flag(:vue_issues_list, project)
    push_frontend_feature_flag(:iteration_cadences, project&.group, default_enabled: :yaml)
  end

  before_action only: :show do
    real_time_enabled = Gitlab::ActionCable::Config.in_app? || Feature.enabled?(:real_time_issue_sidebar, @project)

    push_to_gon_attributes(:features, :real_time_issue_sidebar, real_time_enabled)
    push_frontend_feature_flag(:confidential_notes, @project, default_enabled: :yaml)
    push_frontend_feature_flag(:issue_assignees_widget, @project, default_enabled: :yaml)
    push_frontend_feature_flag(:labels_widget, @project, default_enabled: :yaml)

    experiment(:invite_members_in_comment, namespace: @project.root_ancestor) do |experiment_instance|
      experiment_instance.exclude! unless helpers.can_import_members?

      experiment_instance.use {}
      experiment_instance.try(:invite_member_link) {}

      experiment_instance.track(:view, property: @project.root_ancestor.id.to_s)
    end
  end

  around_action :allow_gitaly_ref_name_caching, only: [:discussions]

  respond_to :html

  alias_method :designs, :show

  feature_category :issue_tracking, [
                     :index, :calendar, :show, :new, :create, :edit, :update,
                     :destroy, :move, :reorder, :designs, :toggle_subscription,
                     :discussions, :bulk_update, :realtime_changes,
                     :toggle_award_emoji, :mark_as_spam, :related_branches,
                     :can_create_branch, :create_merge_request
                   ]

  feature_category :service_desk, [:service_desk]
  feature_category :importers, [:import_csv, :export_csv]

  attr_accessor :vulnerability_id

  def index
    @issues = @issuables

    respond_to do |format|
      format.html
      format.atom { render layout: 'xml.atom' }
      format.json do
        render json: {
          html: view_to_html_string("projects/issues/_issues"),
          labels: @labels.as_json(methods: :text_color)
        }
      end
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
      confidential: !!Gitlab::Utils.to_boolean(issue_params[:confidential])
    )
    service = ::Issues::BuildService.new(project: project, current_user: current_user, params: build_params)

    @issue = @noteable = service.execute

    @merge_request_to_resolve_discussions_of = service.merge_request_to_resolve_discussions_of
    @discussion_to_resolve = service.discussions_to_resolve.first if params[:discussion_to_resolve]

    respond_with(@issue)
  end

  def edit
    respond_with(@issue)
  end

  def create
    extract_legacy_spam_params_to_headers
    create_params = issue_params.merge(
      merge_request_to_resolve_discussions_of: params[:merge_request_to_resolve_discussions_of],
      discussion_to_resolve: params[:discussion_to_resolve]
    )

    spam_params = ::Spam::SpamParams.new_from_request(request: request)
    service = ::Issues::CreateService.new(project: project, current_user: current_user, params: create_params, spam_params: spam_params)
    @issue = service.execute

    create_vulnerability_issue_feedback(issue)

    if service.discussions_to_resolve.count(&:resolved?) > 0
      flash[:notice] = if service.discussion_to_resolve_id
                         _("Resolved 1 discussion.")
                       else
                         _("Resolved all discussions.")
                       end
    end

    respond_to do |format|
      format.html do
        recaptcha_check_with_fallback { render :new }
      end
    end
  end

  def move
    params.require(:move_to_project_id)

    if params[:move_to_project_id].to_i > 0
      new_project = Project.find(params[:move_to_project_id])
      return render_404 unless issue.can_move?(current_user, new_project)

      @issue = ::Issues::MoveService.new(project: project, current_user: current_user).execute(issue, new_project)
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
    service = ::Issues::ReorderService.new(project: project, current_user: current_user, params: reorder_params)

    if service.execute(issue)
      head :ok
    else
      head :unprocessable_entity
    end
  end

  def related_branches
    @related_branches = ::Issues::RelatedBranchesService
      .new(project: project, current_user: current_user)
      .execute(issue)
      .map { |branch| branch.merge(link: branch_link(branch)) }

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
      @issue.can_be_worked_on?

    respond_to do |format|
      format.json do
        render json: { can_create_branch: can_create, suggested_branch_name: @issue.suggested_branch_name }
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
    message = _('Your CSV export has started. It will be emailed to %{email} when complete.') % { email: current_user.notification_email }
    redirect_to(index_path, notice: message)
  end

  def import_csv
    if uploader = UploadService.new(project, params[:file]).execute
      ImportIssuesCsvWorker.perform_async(current_user.id, project.id, uploader.upload.id) # rubocop:disable CodeReuse/Worker

      flash[:notice] = _("Your issues are being imported. Once finished, you'll get a confirmation email.")
    else
      flash[:alert] = _("File upload error.")
    end

    redirect_to project_issues_path(project)
  end

  def service_desk
    @issues = @issuables # rubocop:disable Gitlab/ModuleWithInstanceVariables
    @users.push(User.support_bot) # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end

  protected

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
    params.require(:issue).permit(
      *issue_params_attributes,
      sentry_issue_attributes: [:sentry_issue_identifier]
    )
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
    params.permit(:move_before_id, :move_after_id, :group_full_path)
  end

  def store_uri
    if request.get? && request.format.html?
      store_location_for :user, request.fullpath
    end
  end

  def serializer
    IssueSerializer.new(current_user: current_user, project: issue.project)
  end

  def update_service
    spam_params = ::Spam::SpamParams.new_from_request(request: request)
    ::Issues::UpdateService.new(project: project, current_user: current_user, params: issue_params, spam_params: spam_params)
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

  def finder_options
    options = super

    options[:issue_types] = Issue::TYPES_FOR_LIST

    if service_desk?
      options.reject! { |key| key == 'author_username' || key == 'author_id' }
      options[:author_id] = User.support_bot
    end

    options
  end

  def branch_link(branch)
    project_compare_path(project, from: project.default_branch, to: branch[:name])
  end

  def create_rate_limit
    key = :issues_create

    if rate_limiter.throttled?(key, scope: [@project, @current_user])
      rate_limiter.log_request(request, "#{key}_request_limit".to_sym, current_user)

      render plain: _('This endpoint has been requested too many times. Try again later.'), status: :too_many_requests
    end
  end

  def rate_limiter
    ::Gitlab::ApplicationRateLimiter
  end

  def service_desk?
    action_name == 'service_desk'
  end

  # Overridden in EE
  def create_vulnerability_issue_feedback(issue); end
end

Projects::IssuesController.prepend_mod_with('Projects::IssuesController')
