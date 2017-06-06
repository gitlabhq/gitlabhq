class Admin::AuditLogsController < Admin::ApplicationController
  def index
    @events = LogFinder.new(audit_logs_params).execute
    @entity = case audit_logs_params[:event_type]
              when 'User'
                User.find_by_id(audit_logs_params[:user_id])
              when 'Project'
                Project.find_by_id(audit_logs_params[:project_id])
              when 'Group'
                Namespace.find_by_id(audit_logs_params[:group_id])
              else
                nil
              end
  end

  def audit_logs_params
    params.permit(:page, :event_type, :user_id, :project_id, :group_id)
  end
end
