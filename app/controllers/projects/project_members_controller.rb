class Projects::ProjectMembersController < Projects::ApplicationController
  include MembershipActions

  # Authorize
  before_action :authorize_admin_project_member!, except: [:index, :leave, :request_access]

  def index
    @group_links = @project.project_group_links

    @project_members = @project.project_members
    @project_members = @project_members.non_invite unless can?(current_user, :admin_project, @project)

    if params[:search].present?
      users = @project.users.search(params[:search]).to_a
      @project_members = @project_members.where(user_id: users)

      @group_links = @project.project_group_links.where(group_id: @project.invited_groups.search(params[:search]).select(:id))
    end

    @project_members = @project_members.order(access_level: :desc).page(params[:page])

    @requesters = AccessRequestsFinder.new(@project).execute(current_user)

    @project_member = @project.project_members.new
  end

  def create
    status = Members::CreateService.new(@project, current_user, params).execute

    redirect_url = namespace_project_project_members_path(@project.namespace, @project)

    if status
      members = @project.project_members.where(user_id: params[:user_ids].split(','))

      members.each do |member|
        log_audit_event(member, action: :create)
      end

      redirect_to redirect_url, notice: 'Users were successfully added.'
    else
      redirect_to redirect_url, alert: 'No users or groups specified.'
    end
  end

  def update
    @project_member = @project.project_members.find(params[:id])

    return render_403 unless can?(current_user, :update_project_member, @project_member)

    old_access_level = @project_member.human_access

    if @project_member.update_attributes(member_params)
      log_audit_event(@project_member, action: :update, old_access_level: old_access_level)
    end
  end

  def destroy
    member = Members::DestroyService.new(@project, current_user, params).
      execute(:all)

    log_audit_event(member, action: :destroy)

    respond_to do |format|
      format.html do
        redirect_to namespace_project_project_members_path(@project.namespace, @project)
      end
      format.js { head :ok }
    end
  end

  def resend_invite
    redirect_path = namespace_project_project_members_path(@project.namespace, @project)

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

    redirect_to(namespace_project_project_members_path(project.namespace, project),
                notice: notice)
  end

  protected

  def member_params
    params.require(:project_member).permit(:user_id, :access_level, :expires_at)
  end

  # MembershipActions concern
  alias_method :membershipable, :project
end
