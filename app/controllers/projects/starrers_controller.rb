# frozen_string_literal: true

class Projects::StarrersController < Projects::ApplicationController
  include SortingHelper

  # Authorize
  before_action :require_non_empty_project

  # rubocop: disable CodeReuse/ActiveRecord
  def index
    @sort = params[:sort].presence || sort_value_name

    params[:project] = @project

    @starrers = UsersStarProjectsFinder.new(params).execute
    @starrers = @starrers.sort_by_attribute(@sort)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
