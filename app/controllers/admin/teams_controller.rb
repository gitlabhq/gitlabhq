class Admin::TeamsController < Admin::ApplicationController
  def index
    @teams = UserTeam.order('name ASC')
    @teams = @teams.search(params[:name]) if params[:name].present?
    @teams = @teams.page(params[:page]).per(20)
  end

  def show
    user_team
  end

  def new
    @team = UserTeam.new
  end

  def edit
    user_team
  end

  def create
    @team = UserTeam.new(params[:user_team])
    @team.path = @team.name.dup.parameterize if @team.name
    @team.owner = current_user

    if @team.save
      redirect_to admin_team_path(@team), notice: 'Team of users was successfully created.'
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
      redirect_to admin_team_path(user_team), notice: 'Team of users was successfully updated.'
    else
      render action: "edit"
    end
  end

  def destroy
    user_team.destroy

    redirect_to admin_teams_path, notice: 'Team of users was successfully deleted.'
  end

  protected

  def user_team
    @team ||= UserTeam.find_by_path(params[:id])
  end

end
