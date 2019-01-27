# frozen_string_literal: true

class Projects::StarrersController < Projects::ApplicationController
  include SortingHelper

  # Authorize
  before_action :require_non_empty_project

  # rubocop: disable CodeReuse/ActiveRecord
  def index
    @sort = params[:sort].presence || sort_value_name

    params[:has_starred] = @project

    @starrers = UsersFinder.new(current_user, params).execute
    @starrers = @starrers.joins(:users_star_projects).select('"users".*, "users_star_projects"."created_at" as "starred_since"')
    @starrers = @starrers.sort_by_attribute(@sort)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
