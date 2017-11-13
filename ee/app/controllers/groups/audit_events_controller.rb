class Groups::AuditEventsController < Groups::ApplicationController
  before_action :authorize_admin_group!
  before_action :check_audit_events_available!

  layout 'group_settings'

  def index
    @events = group.audit_events.page(params[:page])
  end
end
