class Teams::ApplicationController < ApplicationController
  protected

  def user_team
    @user_team ||= UserTeam.find_by_path(params[:team_id])
  end

end
