class Projects::ProjectMembersController < Projects::ApplicationController
  include MembershipActions
  include MembersPresentation
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

    @project_members = present_members(@project_members.sort_by_attribute(@sort).page(params[:page]))
    @requesters = present_members(AccessRequestsFinder.new(@project).execute(current_user))
    @project_member = @project.project_members.new
  end

  def import
    @projects = current_user.authorized_projects.order_id_desc
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

  # MembershipActions concern
  alias_method :membershipable, :project
end
