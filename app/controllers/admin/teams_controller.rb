class Admin::TeamsController < Admin::ApplicationController
  before_filter :user_team,
                only: [ :edit, :show, :update, :destroy,
                        :delegate_projects, :relegate_project,
                        :add_members, :remove_member ]

  def index
    @teams = UserTeam.order('name ASC')
    @teams = @teams.search(params[:name]) if params[:name].present?
    @teams = @teams.page(params[:page]).per(20)
  end

  def show
    @projects = Project.scoped
    @projects = @projects.without_team(@team) if @team.projects.any?
    #@projects.reject!(&:empty_repo?)

    @users = User.active
    @users = @users.not_in_team(@team) if @team.members.any?
    @users = UserDecorator.decorate @users
  end

  def new
    @team = UserTeam.new
  end

  def edit
  end

  def create
    @team = UserTeam.new(params[:user_team])
    @team.path = @team.name.dup.parameterize if @team.name
    @team.owner = current_user

    if @team.save
      redirect_to admin_team_path(@team), notice: 'UserTeam was successfully created.'
    else
      render action: "new"
    end
  end

  def update
    user_team_params = params[:user_team].dup
    owner_id = user_team_params.delete(:owner_id)

    if owner_id
      @team.owner = User.find(owner_id)
    end

    if @team.update_attributes(user_team_params)
      redirect_to admin_team_path(@team), notice: 'UserTeam was successfully updated.'
    else
      render action: "edit"
    end
  end

  def destroy
    @team.destroy

    redirect_to admin_user_teams_path, notice: 'UserTeam was successfully deleted.'
  end

  def delegate_projects
    unless params[:project_ids].blank?
      project_ids = params[:project_ids]
      access = params[:greatest_project_access]
      @team.assign_to_projects(project_ids, access)
    end

    redirect_to admin_team_path(@team), notice: 'Projects was successfully added.'
  end

  def relegate_project
    project = params[:project_id]
    @team.resign_from_project(project)

    redirect_to admin_team_path(@team), notice: 'Project was successfully removed.'
  end

  def add_members
    unless params[:user_ids].blank?
      user_ids = params[:user_ids]
      access = params[:default_project_access]
      is_admin = params[:group_admin]
      @team.add_members(user_ids, access, is_admin)
    end

    redirect_to admin_team_path(@team), notice: 'Members was successfully added.'
  end

  def remove_member
    member = params[:member_id]
    @team.remove_member(member)

    redirect_to admin_team_path(@team), notice: 'Member was successfully removed.'
  end

  private

  def user_team
    @team = UserTeam.find_by_path(params[:id])
  end

end
