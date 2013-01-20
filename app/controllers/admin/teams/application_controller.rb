# Provides a base class for Admin controllers to subclass
#
# Automatically sets the layout and ensures an administrator is logged in
class Admin::Teams::ApplicationController < Admin::ApplicationController
  before_filter :user_team

  private

  def user_team
    @team = UserTeam.find_by_path(params[:team_id])
  end
end
