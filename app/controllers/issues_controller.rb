class IssuesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :project
  before_filter :module_enabled
  before_filter :issue, :only => [:edit, :update, :destroy, :show]
  layout "project"

  # Authorize
  before_filter :add_project_abilities

  # Allow read any issue
  before_filter :authorize_read_issue!

  # Allow write(create) issue
  before_filter :authorize_write_issue!, :only => [:new, :create]

  # Allow modify issue
  before_filter :authorize_modify_issue!, :only => [:close, :edit, :update]

  # Allow destroy issue
  before_filter :authorize_admin_issue!, :only => [:destroy]

  respond_to :js, :html

  def index
    @issues = issues_filtered

    @issues = @issues.page(params[:page]).per(20)

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.atom { render :layout => false }
    end
  end

  def new
    @issue = @project.issues.new
    respond_with(@issue)
  end

  def edit
    respond_with(@issue)
  end

  def show
    @note = @project.notes.new(:noteable => @issue)

    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    @issue = @project.issues.new(params[:issue])
    @issue.author = current_user
    @issue.save

    respond_to do |format|
      format.html { redirect_to project_issue_path(@project, @issue) }
      format.js
    end
  end

  def update
    @issue.update_attributes(params[:issue].merge(:author_id_of_changes => current_user.id))

    respond_to do |format|
      format.js
      format.html do 
        if @issue.valid?
          redirect_to [@project, @issue]
        else
          render :edit
        end
      end
    end
  end

  def destroy
    return access_denied! unless can?(current_user, :admin_issue, @issue)

    @issue.destroy

    respond_to do |format|
      format.html { redirect_to project_issues_path }
      format.js { render :nothing => true }
    end
  end

  def sort
    return render_404 unless can?(current_user, :admin_issue, @project)

    @issues = @project.issues.where(:id => params['issue'])
    @issues.each do |issue|
      issue.position = params['issue'].index(issue.id.to_s) + 1
      issue.save
    end

    render :nothing => true
  end

  def search
    terms = params['terms']

    @issues = issues_filtered
    @issues = @issues.where("title LIKE ?", "%#{terms}%") unless terms.blank?
    @issues = @issues.page(params[:page]).per(100)

    render :partial => 'issues'
  end

  protected

  def issue
    @issue ||= @project.issues.find(params[:id])
  end

  def authorize_modify_issue!
    return render_404 unless can?(current_user, :modify_issue, @issue)
  end

  def authorize_admin_issue!
    return render_404 unless can?(current_user, :admin_issue, @issue)
  end

  def module_enabled
    return render_404 unless @project.issues_enabled
  end

  def issues_filtered
    @issues = case params[:f].to_i
              when 1 then @project.issues
              when 2 then @project.issues.closed
              when 3 then @project.issues.opened.assigned(current_user)
              else @project.issues.opened
              end

    @issues = @issues.where(:milestone_id => params[:milestone_id]) if params[:milestone_id].present?
    @issues = @issues.includes(:author, :project).order("critical, updated_at")
    @issues
  end
end
