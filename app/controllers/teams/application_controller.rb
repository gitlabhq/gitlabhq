class Teams::ApplicationController < ApplicationController

  before_filter :authorize_manage_user_team!

  protected

  def user_team
    @user_team ||= UserTeam.find_by_path(params[:team_id])
  end

  def authorize_manage_user_team!
    return access_denied! unless can?(current_user, :manage_user_team, user_team)
  end

end
