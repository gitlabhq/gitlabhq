class Projects::ApplicationController < ApplicationController

  before_filter :authorize_admin_team_member!

  protected

  def user_team
    @team ||= UserTeam.find_by_path(params[:id])
  end

end
