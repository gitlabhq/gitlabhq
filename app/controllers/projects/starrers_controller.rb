# frozen_string_literal: true

class Projects::StarrersController < Projects::ApplicationController
  include SortingHelper

  # Authorize
  before_action :require_non_empty_project

  def index
    @sort = params[:sort].presence || sort_value_name

    @starrers = UsersStarProjectsFinder.new(@project, params, current_user: @current_user).execute

    @total_count = @project.starrers.size
    @public_count = @starrers.size
    @private_count = @total_count - @public_count

    @starrers = @starrers.sort_by_attribute(@sort).page(params[:page])
  end
end
