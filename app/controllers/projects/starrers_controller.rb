# frozen_string_literal: true

class Projects::StarrersController < Projects::ApplicationController
  include SortingHelper

  feature_category :groups_and_projects

  urgency :low, [:index]

  def index
    @starrers = UsersStarProjectsFinder.new(
      @project, starrer_filter_params.slice(:search), current_user: @current_user
    ).execute
    @sort = starrer_filter_params[:sort].presence || sort_value_name
    @starrers = @starrers.preload_users.sort_by_attribute(@sort).page(starrer_filter_params[:page])
    @public_count = @project.starrers.active.with_public_profile.size
    @total_count = @project.starrers.active.size
    @private_count = @total_count - @public_count
  end

  private

  def starrer_filter_params
    params.permit(:search, :sort, :page)
  end
end
