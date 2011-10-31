class DashboardController < ApplicationController
  def index
    @projects = current_user.projects.all
    @active_projects = @projects.select(&:last_activity_date).sort_by(&:last_activity_date).reverse
  end
end
