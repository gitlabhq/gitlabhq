class AuditEventsController < ApplicationController
  # Authorize
  before_filter :repository, only: :project_log
  before_filter :authorize_admin_project!, only: :project_log

  layout "project_settings"

  def project_log
    @events = AuditEvent.where(entity_type: "Project", entity_id: project.id)
  end

  private

  def audit_events_params
    params.permit(:project_id)
  end
end
