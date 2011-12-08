class UserMergeRequestsController < ApplicationController
  before_filter :authenticate_user!

  def index
    @projects = current_user.projects.all
    @merge_requests = current_user.assigned_merge_requests
  end
end
