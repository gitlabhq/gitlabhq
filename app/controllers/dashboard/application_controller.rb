# frozen_string_literal: true

class Dashboard::ApplicationController < ApplicationController
  include ControllerWithCrossProjectAccessCheck
  include RecordUserLastActivity
  include SignInDashboardUxSli

  layout 'dashboard'

  requires_cross_project_access

  after_action :observe_sign_in_dashboard_ux_sli

  private

  def projects
    @projects ||= current_user.authorized_projects.sorted_by_activity.non_archived
  end
end

Dashboard::ApplicationController.prepend_mod
