class Teams::ApplicationController < ApplicationController

  before_filter :authorize_manage_user_team!

  protected

  def user_team
    @team ||= UserTeam.find_by_path(params[:team_id])
  end

end
