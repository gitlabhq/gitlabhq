# frozen_string_literal: true

class Projects::StarrersController < Projects::ApplicationController
  include SortingHelper

  def index
    @starrers = UsersStarProjectsFinder.new(@project, params, current_user: @current_user).execute

    # Normally the number of public starrers is equal to the number of visible
    # starrers. We need to fix the counts in two cases: when the current user
    # is an admin (and can see everything) and when the current user has a
    # private profile and has starred the project (and can see itself).
    @public_count =
      if @current_user&.admin?
        @starrers.with_public_profile.count
      elsif @current_user&.private_profile && has_starred_project?(@starrers)
        @starrers.size - 1
      else
        @starrers.size
      end

    @total_count = @project.starrers.size
    @private_count = @total_count - @public_count

    @sort = params[:sort].presence || sort_value_name
    @starrers = @starrers.sort_by_attribute(@sort).page(params[:page])
  end

  private

  def has_starred_project?(starrers)
    starrers.first { |starrer| starrer.user_id == current_user.id }
  end
end
