class Projects::IssuesController < Projects::ApplicationController
  before_action :module_enabled
  before_action :issue, only: [:edit, :update, :show, :toggle_subscription]

  # Allow read any issue
  before_action :authorize_read_issue!

  # Allow write(create) issue
  before_action :authorize_create_issue!, only: [:new, :create]

  # Allow modify issue
  before_action :authorize_update_issue!, only: [:edit, :update]

  # Allow issues bulk update
  before_action :authorize_admin_issues!, only: [:bulk_update]

  # Cross-reference merge requests
  before_action :closed_by_merge_requests, only: [:show]

  respond_to :html

  def index
    terms = params['issue_search']
    @issues = get_issues_collection

    if terms.present?
      if terms =~ /\A#(\d+)\z/
        @issues = @issues.where(iid: $1)
      else
        @issues = @issues.full_search(terms)
      end
    end

    @issues = @issues.page(params[:page]).per(PER_PAGE)
    @label = @project.labels.find_by(title: params[:label_name])

    respond_to do |format|
      format.html
      format.atom { render layout: false }
      format.json do
        render json: {
          html: view_to_html_string("projects/issues/_issues")
        }
      end
    end
  end

  def new
    params[:issue] ||= ActionController::Parameters.new(
      assignee_id: ""
    )

    @issue = @noteable = @project.issues.new(issue_params)
    respond_with(@issue)
  end

  def edit
    respond_with(@issue)
  end

  def show
    @note = @project.notes.new(noteable: @issue)
    @notes = @issue.notes.nonawards.with_associations.fresh
    @noteable = @issue
    @merge_requests = @issue.referenced_merge_requests(current_user)

    respond_with(@issue)
  end

  def create
    @issue = Issues::CreateService.new(project, current_user, issue_params).execute

    respond_to do |format|
      format.html do
        if @issue.valid?
          redirect_to issue_path(@issue)
        else
          render :new
        end
      end
      format.js do |format|
        @link = @issue.attachment.url.to_js
      end
    end
  end

  def update
    @issue = Issues::UpdateService.new(project, current_user, issue_params).execute(issue)

    respond_to do |format|
      format.js
      format.html do
        if @issue.valid?
          redirect_to issue_path(@issue)
        else
          render :edit
        end
      end
      format.json do
        render json: {
          saved: @issue.valid?,
          assignee_avatar_url: @issue.assignee.try(:avatar_url)
        }
      end
    end
  end

  def bulk_update
    result = Issues::BulkUpdateService.new(project, current_user, bulk_update_params).execute
    redirect_back_or_default(default: { action: 'index' }, options: { notice: "#{result[:count]} issues updated" })
  end

  def toggle_subscription
    @issue.toggle_subscription(current_user)

    render nothing: true
  end

  def closed_by_merge_requests
    @closed_by_merge_requests ||= @issue.closed_by_merge_requests(current_user)
  end

  protected

  def issue
    @issue ||= begin
                 @project.issues.find_by!(iid: params[:id])
               rescue ActiveRecord::RecordNotFound
                 redirect_old
               end
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
      :title, :assignee_id, :position, :description,
      :milestone_id, :state_event, :task_num, label_ids: []
    )
  end

  def bulk_update_params
    params.require(:update).permit(
      :issues_ids,
      :assignee_id,
      :milestone_id,
      :state_event
    )
  end
end
