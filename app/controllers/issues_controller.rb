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
  before_filter :authorize_modify_issue!, :only => [:close, :edit, :update, :sort]

  # Allow destroy issue
  before_filter :authorize_admin_issue!, :only => [:destroy]

  respond_to :js, :html

  def index
    @issues = case params[:f].to_i
              when 1 then @project.issues
              when 2 then @project.issues.closed
              when 3 then @project.issues.opened.assigned(current_user)
              else @project.issues.opened
              end

    @issues = @issues.includes(:author, :project)

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
    @notes = @issue.notes.inc_author.order("created_at DESC").limit(20)
    @note = @project.notes.new(:noteable => @issue)

    @commits = if @issue.branch_name && @project.repo.heads.map(&:name).include?(@issue.branch_name)
                 @project.repo.commits_between("master", @issue.branch_name)
               else 
                 []
               end


    respond_to do |format|
      format.html
      format.js { respond_with_notes }
    end
  end

  def create
    @issue = @project.issues.new(params[:issue])
    @issue.author = current_user
    @issue.save

    respond_with(@issue)
  end

  def update
    @issue.update_attributes(params[:issue])

    respond_to do |format|
      format.js
      format.html { redirect_to [@project, @issue]}
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
    @issues = @project.issues.where(:id => params['issue'])
    @issues.each do |issue|
      issue.position = params['issue'].index(issue.id.to_s) + 1
      issue.save
    end

    render :nothing => true
  end

  def search
    terms = params['terms']

    @project  = Project.find(params['project'])
    @issues   = case params[:status].to_i
                  when 1 then @project.issues
                  when 2 then @project.issues.closed
                  when 3 then @project.issues.opened.assigned(current_user)
                  else @project.issues.opened
                end

    @issues = @issues.where("title LIKE ?", "%#{terms}%") unless terms.blank?

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
end
