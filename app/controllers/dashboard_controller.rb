class DashboardController < ApplicationController
  def index
    @projects = current_user.projects.all
  end
end
