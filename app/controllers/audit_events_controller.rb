class AuditEventsController < ApplicationController
  # Authorize
  before_filter :repository, only: :project_log
  before_filter :authorize_admin_project!, only: :project_log
  before_filter :group, only: :group_log
  before_filter :authorize_admin_group!, only: :group_log

  layout :determine_layout

  def project_log
    @events = AuditEvent.where(entity_type: "Project", entity_id: project.id).page(params[:page]).per(30)
  end

  def group_log
    @events = AuditEvent.where(entity_type: "Group", entity_id: group.id).page(params[:page]).per(30)
  end

  private

  def group
    @group ||= Group.find_by(path: params[:group_id])
  end

  def authorize_admin_group!
    render_404 unless can?(current_user, :manage_group, group)
  end

  def determine_layout
    if @project
      'project_settings'
    elsif @group
      'group'
    end
  end

  def audit_events_params
    params.permit(:project_id, :group_id)
  end
end
