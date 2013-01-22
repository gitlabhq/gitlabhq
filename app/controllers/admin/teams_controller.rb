class Admin::TeamsController < Admin::ApplicationController
  def index
    @teams = UserTeam.order('name ASC')
    @teams = @teams.search(params[:name]) if params[:name].present?
    @teams = @teams.page(params[:page]).per(20)
  end

  def show
    @projects = Project.scoped
    @projects = @projects.without_team(user_team) if user_team.projects.any?
    #@projects.reject!(&:empty_repo?)

    @users = User.active
    @users = @users.not_in_team(user_team) if user_team.members.any?
    @users = UserDecorator.decorate @users
  end

  def new
    @team = UserTeam.new
  end

  def edit
    user_team
  end

  def create
    user_team = UserTeam.new(params[:user_team])
    user_team.path = user_team.name.dup.parameterize if user_team.name
    user_team.owner = current_user

    if user_team.save
      redirect_to admin_team_path(user_team), notice: 'UserTeam was successfully created.'
    else
      render action: "new"
    end
  end

  def update
    user_team_params = params[:user_team].dup
    owner_id = user_team_params.delete(:owner_id)

    if owner_id
      user_team.owner = User.find(owner_id)
    end

    if user_team.update_attributes(user_team_params)
      redirect_to admin_team_path(user_team), notice: 'UserTeam was successfully updated.'
    else
      render action: "edit"
    end
  end

  def destroy
    user_team.destroy

    redirect_to admin_user_teams_path, notice: 'UserTeam was successfully deleted.'
  end

  protected

  def user_team
    @team ||= UserTeam.find_by_path(params[:id])
  end

end
