class Projects::IssuesController < Projects::ApplicationController
  include NotesHelper
  include ToggleSubscriptionAction
  include IssuableActions
  include ToggleAwardEmoji
  include IssuableCollections
  include SpammableActions

  before_action :redirect_to_external_issue_tracker, only: [:index, :new]
  before_action :module_enabled
  before_action :issue, only: [:edit, :update, :show, :referenced_merge_requests,
                               :related_branches, :can_create_branch]

  # Allow read any issue
  before_action :authorize_read_issue!, only: [:show]

  # Allow write(create) issue
  before_action :authorize_create_issue!, only: [:new, :create]

  # Allow modify issue
  before_action :authorize_update_issue!, only: [:edit, :update]

  # Allow issues bulk update
  before_action :authorize_admin_issues!, only: [:bulk_update]

  respond_to :html

  def index
    terms = params['issue_search']
    @issues = issues_collection

    if terms.present?
      if terms =~ /\A#(\d+)\z/
        @issues = @issues.where(iid: $1)
      else
        @issues = @issues.full_search(terms)
      end
    end

    @issues = @issues.page(params[:page])
    @labels = @project.labels.where(title: params[:label_name])

    respond_to do |format|
      format.html
      format.atom { render layout: false }
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
      assignee_id: ""
    )

    @issue = @noteable = @project.issues.new(issue_params)

    # Set Issue description based on project template
    if @project.issues_template.present?
      @issue.description = @project.issues_template
    end

    respond_with(@issue)
  end

  def edit
    respond_with(@issue)
  end

  def show
    raw_notes = @issue.notes_with_associations.fresh

    @notes = Banzai::NoteRenderer.
      render(raw_notes, @project, current_user, @path, @project_wiki, @ref)

    @note     = @project.notes.new(noteable: @issue)
    @noteable = @issue

    preload_max_access_for_authors(@notes, @project)

    respond_to do |format|
      format.html
      format.json do
        render json: @issue.to_json(include: [:milestone, :labels])
      end
    end
  end

  def create
    @issue = Issues::CreateService.new(project, current_user, issue_params.merge(request: request)).execute

    respond_to do |format|
      format.html do
        if @issue.valid?
          redirect_to issue_path(@issue)
        else
          render :new
        end
      end
      format.js do
        @link = @issue.attachment.url.to_js
      end
    end
  end

  def update
    @issue = Issues::UpdateService.new(project, current_user, issue_params).execute(issue)

    if params[:move_to_project_id].to_i > 0
      new_project = Project.find(params[:move_to_project_id])
      return render_404 unless issue.can_move?(current_user, new_project)

      move_service = Issues::MoveService.new(project, current_user)
      @issue = move_service.execute(@issue, new_project)
    end

    respond_to do |format|
      format.html do
        if @issue.valid?
          redirect_to issue_path(@issue)
        else
          render :edit
        end
      end

      format.json do
        render json: @issue.to_json(include: { milestone: {}, assignee: { methods: :avatar_url }, labels: { methods: :text_color } })
      end
    end
  end

  def referenced_merge_requests
    @merge_requests = @issue.referenced_merge_requests(current_user)
    @closed_by_merge_requests = @issue.closed_by_merge_requests(current_user)

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
        render json: { can_create_branch: can_create }
      end
    end
  end

  def bulk_update
    result = Issues::BulkUpdateService.new(project, current_user, bulk_update_params).execute

    respond_to do |format|
      format.json do
        render json: { notice: "#{result[:count]} issues updated" }
      end
    end
  end

  protected

  def issue
    @issue ||= begin
                 @project.issues.find_by!(iid: params[:id])
               rescue ActiveRecord::RecordNotFound
                 redirect_old
               end
  end
  alias_method :subscribable_resource, :issue
  alias_method :issuable, :issue
  alias_method :awardable, :issue
  alias_method :spammable, :issue

  def authorize_read_issue!
    return render_404 unless can?(current_user, :read_issue, @issue)
  end

  def authorize_update_issue!
    return render_404 unless can?(current_user, :update_issue, @issue)
  end

  def authorize_admin_issues!
    return render_404 unless can?(current_user, :admin_issue, @project)
  end

  def module_enabled
    return render_404 unless @project.issues_enabled && @project.default_issues_tracker?
  end

  def redirect_to_external_issue_tracker
    external = @project.external_issue_tracker

    return unless external

    if action_name == 'new'
      redirect_to external.new_issue_path
    else
      redirect_to external.issues_url
    end
  end

  # Since iids are implemented only in 6.1
  # user may navigate to issue page using old global ids.
  #
  # To prevent 404 errors we provide a redirect to correct iids until 7.0 release
  #
  def redirect_old
    issue = @project.issues.find_by(id: params[:id])

    if issue
      redirect_to issue_path(issue)
      return
    else
      raise ActiveRecord::RecordNotFound.new
    end
  end

  def issue_params
    params.require(:issue).permit(
      :title, :assignee_id, :position, :description, :confidential, :weight,
      :milestone_id, :due_date, :state_event, :task_num, label_ids: []
    )
  end

  def bulk_update_params
    params.require(:update).permit(
      :issues_ids,
      :assignee_id,
      :milestone_id,
      :state_event,
      :subscription_event,
      label_ids: [],
      add_label_ids: [],
      remove_label_ids: []
    )
  end
end
