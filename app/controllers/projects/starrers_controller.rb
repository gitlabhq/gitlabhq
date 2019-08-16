# frozen_string_literal: true

class Projects::StarrersController < Projects::ApplicationController
  include SortingHelper

  def index
    @starrers = UsersStarProjectsFinder.new(@project, params, current_user: @current_user).execute
    @public_count  = @project.starrers.with_public_profile.size
    @total_count   = @project.starrers.size
    @private_count = @total_count - @public_count
    @sort = params[:sort].presence || sort_value_name
    @starrers = @starrers.sort_by_attribute(@sort).page(params[:page])
  end

  private

  def has_starred_project?(starrers)
    starrers.first { |starrer| starrer.user_id == current_user.id }
  end
end
