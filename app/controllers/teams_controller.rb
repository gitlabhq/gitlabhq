class TeamsController < ApplicationController
  respond_to :html
  layout 'user_team',       only: [:show, :edit, :update, :destroy, :issues, :merge_requests, :search]

  before_filter :user_team, only: [:show, :edit, :update, :destroy, :issues, :merge_requests, :search]
  before_filter :projects,  only: [:show, :edit, :update, :destroy, :issues, :merge_requests, :search]

  # Authorize
  before_filter :authorize_manage_user_team!, only: [:edit, :update]
  before_filter :authorize_admin_user_team!, only: [:destroy]

  def index
    @teams = UserTeam.all
  end

  def show
    @events = Event.in_projects(project_ids).limit(20).offset(params[:offset] || 0)

    respond_to do |format|
      format.html
      format.js
      format.atom { render layout: false }
    end
  end

  def edit

  end

  def update
    if user_team.update_attributes(params[:user_team])
      redirect_to team_path(user_team)
    else
      render action: :edit
    end
  end

  def destroy
    user_team.destroy
    redirect_to teams_path
  end

  def new
    @team = UserTeam.new
  end

  def create
    @team = UserTeam.new(params[:user_team])
    @team.owner = current_user unless params[:owner]
    @team.path = @team.name.dup.parameterize if @team.name

    if @team.save
      redirect_to team_path(@team)
    else
      render action: :new
    end
  end

  # Get authored or assigned open merge requests
  def merge_requests
    @merge_requests = MergeRequest.of_user_team(@user_team)
    @merge_requests = FilterContext.new(@merge_requests, params).execute
    @merge_requests = @merge_requests.recent.page(params[:page]).per(20)
  end

  # Get only assigned issues
  def issues
    @issues = Issue.of_user_team(@user_team)
    @issues = FilterContext.new(@issues, params).execute
    @issues = @issues.recent.page(params[:page]).per(20)
    @issues = @issues.includes(:author, :project)

    respond_to do |format|
      format.html
      format.atom { render layout: false }
    end
  end

  def search
    result = SearchContext.new(project_ids, params).execute

    @projects       = result[:projects]
    @merge_requests = result[:merge_requests]
    @issues         = result[:issues]
    @wiki_pages     = result[:wiki_pages]
  end

  protected

  def user_team
    @user_team ||= UserTeam.find_by_path(params[:id])
  end

  def projects
    @projects ||= user_team.projects.sorted_by_activity
  end

  def project_ids
    projects.map(&:id)
  end

  def authorize_manage_user_team!
    unless user_team.present? or can?(current_user, :manage_user_team, user_team)
      return render_404
    end
  end

  def authorize_admin_user_team!
    unless user_team.owner == current_user || current_user.admin?
      return render_404
    end
  end
end
