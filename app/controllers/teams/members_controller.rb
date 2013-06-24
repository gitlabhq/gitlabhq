class Teams::MembersController < Teams::ApplicationController

  skip_before_filter :authorize_manage_user_team!, only: [:index]

  def index
    @members = user_team.members
  end

  def new
    @users = User.potential_team_members(user_team)
  end

  def create
    ::Teams::Users::CreateRelationContext.new(@current_user, user_team, params).execute

    redirect_to team_members_path(user_team), notice: 'Members were successfully added into Team of users.'
  end

  def edit
    team_member
  end

  def update
    if ::Teams::Users::UpdateRelationContext.new(@current_user, user_team, team_member, params).execute
      redirect_to team_members_path(user_team), notice: "Membership for #{team_member.name} was successfully updated in Team of users."
    else
      render :edit
    end
  end

  def destroy
    ::Teams::Users::RemoveRelationContext.new(@current_user, user_team, team_member).execute
    redirect_to team_path(user_team), notice: "Member #{team_member.name} was successfully removed from Team of users."
  end

  protected

  def team_member
    @member ||= user_team.members.find_by_username(params[:id])
  end
end
