class Projects::ProjectMembersController < Projects::ApplicationController
  include MembershipActions
  include SortingHelper

  # Authorize
  before_action :authorize_admin_project_member!, except: [:index, :leave, :request_access]

  def index
    sort = params[:sort].presence || sort_value_name
    redirect_to project_settings_members_path(@project, sort: sort)
  end

  def update
    @project_member = @project.project_members.find(params[:id])

    return render_403 unless can?(current_user, :update_project_member, @project_member)

    @project_member.update_attributes(member_params)
  end

  def resend_invite
    redirect_path = project_settings_members_path(@project)

    @project_member = @project.project_members.find(params[:id])

    if @project_member.invite?
      @project_member.resend_invite

      redirect_to redirect_path, notice: 'The invitation was successfully resent.'
    else
      redirect_to redirect_path, alert: 'The invitation has already been accepted.'
    end
  end

  def apply_import
    source_project = Project.find(params[:source_project_id])

    if can?(current_user, :read_project_member, source_project)
      status = @project.team.import(source_project, current_user)
      notice = status ? "Successfully imported" : "Import failed"
    else
      return render_404
    end

    redirect_to(project_settings_members_path(project),
                notice: notice)
  end

  protected

  def member_params
    params.require(:project_member).permit(:user_id, :access_level, :expires_at)
  end

  # MembershipActions concern
  alias_method :membershipable, :project
end
