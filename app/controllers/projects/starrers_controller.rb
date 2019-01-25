# frozen_string_literal: true

class Projects::StarrersController < Projects::ApplicationController
  include SortingHelper
  #
  # Authorize
  before_action :require_non_empty_project

  def index
    @sort = params[:sort].presence || sort_value_name

    params[:has_starred] = @project

    @starrers = UsersFinder.new(current_user, params).execute
    @starrers = @starrers.sort_by_attribute(@sort)
  end
end
