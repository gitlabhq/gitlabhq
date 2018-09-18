# frozen_string_literal: true
class Groups::Security::DashboardController < Groups::ApplicationController
  before_action :group

  layout 'group'

  # Redirecting back to the group path till the page is ready
  def show
    redirect_to group_path(@group)
  end
end
