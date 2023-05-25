# frozen_string_literal: true

class Projects::StarrersController < Projects::ApplicationController
  include SortingHelper

  feature_category :groups_and_projects

  urgency :low, [:index]

  def index
    @starrers = UsersStarProjectsFinder.new(@project, params, current_user: @current_user).execute
    @sort = params[:sort].presence || sort_value_name
    @starrers = @starrers.preload_users.sort_by_attribute(@sort).page(params[:page])
    @public_count = @project.starrers.active.with_public_profile.size
    @total_count = @project.starrers.active.size
    @private_count = @total_count - @public_count
  end
end
