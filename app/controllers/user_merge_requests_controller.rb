class UserMergeRequestsController < ApplicationController
  before_filter :authenticate_user!

  layout "user"

  def index
    @merge_requests = current_user.assigned_merge_requests
  end
end
