class Projects::AuditEventsController < Projects::ApplicationController
  include LicenseHelper

  before_action :authorize_admin_project!
  before_action :check_audit_events_available!

  layout 'project_settings'

  def index
    @events = project.audit_events.page(params[:page])
  end

  def check_audit_events_available!
    render_404 unless @project.feature_available?(:audit_events) || LicenseHelper.show_promotions?(current_user)
  end
end
