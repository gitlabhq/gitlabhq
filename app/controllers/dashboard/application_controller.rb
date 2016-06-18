class Dashboard::ApplicationController < ApplicationController
  layout 'dashboard'

  private

  def projects
    @projects ||= current_user.authorized_projects.sorted_by_activity.non_archived
  end
end
