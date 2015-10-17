class Projects::ExceptionsController < Projects::ApplicationController
  before_action :module_enabled
  before_action :exception, only: [:edit, :update, :show, :toggle_subscription]

  # # Allow read any issue
  # before_action :authorize_read_issue!

  # # Allow write(create) issue
  # before_action :authorize_create_issue!, only: [:new, :create]

  # # Allow modify issue
  # before_action :authorize_update_issue!, only: [:edit, :update]

  # # Allow issues bulk update
  # before_action :authorize_admin_issues!, only: [:bulk_update]

  respond_to :html

  def index
    @exceptions = @project.exceptions.page(params[:page]).per(PER_PAGE)

    respond_to do |format|
      format.html
      format.atom { render layout: false }
      format.json do
        render json: {
          html: view_to_html_string("projects/exceptions/_exceptions")
        }
      end
    end
  end

  def new
    params[:issue] ||= ActionController::Parameters.new(
      assignee_id: ""
    )

    @issue = @project.issues.new(issue_params)
    respond_with(@issue)
  end

  def show
    @participants = @issue.participants(current_user)
    @note = @project.notes.new(noteable: @issue)
    @notes = @issue.notes.with_associations.fresh
    @noteable = @issue

    respond_with(@issue)
  end

  protected

  def exception
    @exception ||= begin
                 @project.exceptions.find(params[:id])
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
    return render_404 unless @project.exceptions_enabled
  end

end