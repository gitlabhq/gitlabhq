class Teams::ApplicationController < ApplicationController
  before_filter :user_team, only: [:index, :show, :edit, :update, :destroy, :issues, :merge_requests, :search, :members]

  protected

  def user_team
    @user_team ||= UserTeam.find_by_path(params[:team_id])
  end

end
