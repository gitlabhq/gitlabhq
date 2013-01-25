class TeamsController < ApplicationController
  # Authorize
  before_filter :authorize_create_team!, only: [:new, :create]
  before_filter :authorize_manage_user_team!, only: [:edit, :update]
  before_filter :authorize_admin_user_team!, only: [:destroy]

  before_filter :user_team, except: [:new, :create]

  layout 'user_team', except: [:new, :create]

  def show
    user_team
    projects
    @events = Event.in_projects(user_team.project_ids).limit(20).offset(params[:offset] || 0)
  end

  def edit
    user_team
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
    redirect_to dashboard_path
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
    projects
    @merge_requests = MergeRequest.of_user_team(user_team)
    @merge_requests = FilterContext.new(@merge_requests, params).execute
    @merge_requests = @merge_requests.recent.page(params[:page]).per(20)
  end

  # Get only assigned issues
  def issues
    projects
    @issues = Issue.of_user_team(user_team)
    @issues = FilterContext.new(@issues, params).execute
    @issues = @issues.recent.page(params[:page]).per(20)
    @issues = @issues.includes(:author, :project)
  end

  protected

  def projects
    @projects ||= user_team.projects.sorted_by_activity
  end

  def user_team
    @team ||= current_user.authorized_teams.find_by_path(params[:id])
  end
end
