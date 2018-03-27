class Dashboard::ApplicationController < ApplicationController
  include ControllerWithCrossProjectAccessCheck

  layout 'dashboard'

  requires_cross_project_access

  private

  def projects
    @projects ||= current_user.authorized_projects.sorted_by_activity.non_archived
  end
end
