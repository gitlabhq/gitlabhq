class Projects::ProjectMembersController < Projects::ApplicationController
  include MembershipActions
  include SortingHelper

  # Authorize
  before_action :authorize_admin_project_member!, except: [:index, :leave, :request_access]

  def index
    @sort = params[:sort].presence || sort_value_name
    @group_links = @project.project_group_links

    @skip_groups = @group_links.pluck(:group_id)
    @skip_groups << @project.namespace_id unless @project.personal?
    @skip_groups += @project.group.ancestors.pluck(:id) if @project.group

    @project_members = MembersFinder.new(@project, current_user).execute

    if params[:search].present?
      @project_members = @project_members.joins(:user).merge(User.search(params[:search]))
      @group_links = @group_links.where(group_id: @project.invited_groups.search(params[:search]).select(:id))
    end

    @project_members = @project_members.sort(@sort).page(params[:page])
    @requesters = AccessRequestsFinder.new(@project).execute(current_user)
    @project_member = @project.project_members.new
  end

  def update
    @project_member = @project.project_members.find(params[:id])

    return render_403 unless can?(current_user, :update_project_member, @project_member)

    old_access_level = @project_member.human_access

    if @project_member.update_attributes(member_params)
      log_audit_event(@project_member, action: :update, old_access_level: old_access_level)
    end
  end

  def resend_invite
    redirect_path = project_project_members_path(@project)

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

    redirect_to(project_project_members_path(project),
                notice: notice)
  end

  protected

  def member_params
    params.require(:project_member).permit(:user_id, :access_level, :expires_at)
  end

  # MembershipActions concern
  alias_method :membershipable, :project
end
