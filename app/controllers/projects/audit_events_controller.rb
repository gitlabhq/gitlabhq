class Projects::AuditEventsController < Projects::ApplicationController
  before_action :authorize_admin_project!

  layout 'project_settings'

  def index
    @events = project.audit_events.page(params[:page])
  end
end
