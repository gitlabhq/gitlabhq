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

  private

  def user_team
    @team = UserTeam.find_by_path(params[:id])
  end

end
