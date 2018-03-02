class Projects::IssuesController < Projects::ApplicationController
  include RendersNotes
  include ToggleSubscriptionAction
  include IssuableActions
  include ToggleAwardEmoji
  include IssuableCollections
  include SpammableActions

  prepend_before_action :authenticate_user!, only: [:new]

  before_action :whitelist_query_limiting, only: [:create, :create_merge_request, :move, :bulk_update]
  before_action :check_issues_available!
  before_action :issue, except: [:index, :new, :create, :bulk_update]
  before_action :set_issuables_index, only: [:index]

  # Allow write(create) issue
  before_action :authorize_create_issue!, only: [:new, :create]

  # Allow modify issue
  before_action :authorize_update_issuable!, only: [:edit, :update, :move]

  # Allow create a new branch and empty WIP merge request from current issue
  before_action :authorize_create_merge_request!, only: [:create_merge_request]

  respond_to :html

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

  def new
    params[:issue] ||= ActionController::Parameters.new(
      assignee_ids: ""
    )
    build_params = issue_params.merge(
      merge_request_to_resolve_discussions_of: params[:merge_request_to_resolve_discussions_of],
      discussion_to_resolve: params[:discussion_to_resolve]
    )
    service = Issues::BuildService.new(project, current_user, build_params)

    @issue = @noteable = service.execute
    @merge_request_to_resolve_discussions_of = service.merge_request_to_resolve_discussions_of
    @discussion_to_resolve = service.discussions_to_resolve.first if params[:discussion_to_resolve]

    respond_with(@issue)
  end

  def edit
    respond_with(@issue)
  end

  def create
    create_params = issue_params.merge(spammable_params).merge(
      merge_request_to_resolve_discussions_of: params[:merge_request_to_resolve_discussions_of],
      discussion_to_resolve: params[:discussion_to_resolve]
    )

    service = Issues::CreateService.new(project, current_user, create_params)
    @issue = service.execute

    if service.discussions_to_resolve.count(&:resolved?) > 0
      flash[:notice] = if service.discussion_to_resolve_id
                         "Resolved 1 discussion."
                       else
                         "Resolved all discussions."
                       end
    end

    respond_to do |format|
      format.html do
        recaptcha_check_with_fallback { render :new }
      end
      format.js do
        @link = @issue.attachment.url.to_js
      end
    end
  end

  def move
    params.require(:move_to_project_id)

    if params[:move_to_project_id].to_i > 0
      new_project = Project.find(params[:move_to_project_id])
      return render_404 unless issue.can_move?(current_user, new_project)

      @issue = Issues::UpdateService.new(project, current_user, target_project: new_project).execute(issue)
    end

    respond_to do |format|
      format.json do
        render_issue_json
      end
    end

  rescue ActiveRecord::StaleObjectError
    render_conflict_response
  end

  def referenced_merge_requests
    @merge_requests, @closed_by_merge_requests = ::Issues::FetchReferencedMergeRequestsService.new(project, current_user).execute(issue)

    respond_to do |format|
      format.json do
        render json: {
          html: view_to_html_string('projects/issues/_merge_requests')
        }
      end
    end
  end

  def related_branches
    @related_branches = @issue.related_branches(current_user)

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
      @issue.can_be_worked_on?(current_user)

    respond_to do |format|
      format.json do
        render json: { can_create_branch: can_create, has_related_branch: @issue.has_related_branch? }
      end
    end
  end

  def create_merge_request
    create_params = params.slice(:branch_name, :ref).merge(issue_iid: issue.iid)
    result = ::MergeRequests::CreateFromIssueService.new(project, current_user, create_params).execute

    if result[:status] == :success
      render json: MergeRequestCreateSerializer.new.represent(result[:merge_request])
    else
      render json: result[:messsage], status: :unprocessable_entity
    end
  end

  protected

  def issue
    return @issue if defined?(@issue)

    # The Sortable default scope causes performance issues when used with find_by
    @issuable = @noteable = @issue ||= @project.issues.where(iid: params[:id]).reorder(nil).take!
    @note = @project.notes.new(noteable: @issuable)

    return render_404 unless can?(current_user, :read_issue, @issue)

    @issue
  end
  alias_method :subscribable_resource, :issue
  alias_method :issuable, :issue
  alias_method :awardable, :issue
  alias_method :spammable, :issue

  def spammable_path
    project_issue_path(@project, @issue)
  end

  def authorize_create_merge_request!
    render_404 unless can?(current_user, :push_code, @project) && @issue.can_be_worked_on?(current_user)
  end

  def render_issue_json
    if @issue.valid?
      render json: serializer.represent(@issue)
    else
      render json: { errors: @issue.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def issue_params
    params.require(:issue).permit(*issue_params_attributes)
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
    ] + [{ label_ids: [], assignee_ids: [] }]
  end

  def authenticate_user!
    return if current_user

    notice = "Please sign in to create the new issue."

    if request.get? && !request.xhr?
      store_location_for :user, request.fullpath
    end

    redirect_to new_user_session_path, notice: notice
  end

  def serializer
    IssueSerializer.new(current_user: current_user, project: issue.project)
  end

  def update_service
    update_params = issue_params.merge(spammable_params)
    Issues::UpdateService.new(project, current_user, update_params)
  end

  def finder_type
    IssuesFinder
  end

  def whitelist_query_limiting
    # Also see the following issues:
    #
    # 1. https://gitlab.com/gitlab-org/gitlab-ce/issues/42423
    # 2. https://gitlab.com/gitlab-org/gitlab-ce/issues/42424
    # 3. https://gitlab.com/gitlab-org/gitlab-ce/issues/42426
    Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-ce/issues/42422')
  end
end
