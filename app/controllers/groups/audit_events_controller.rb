class Groups::AuditEventsController < Groups::ApplicationController
  before_action :authorize_admin_group!

  layout 'group_settings'

  def index
    @events = group.audit_events.page(params[:page])
  end
end
