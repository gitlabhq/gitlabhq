# frozen_string_literal: true

class Projects::ProjectMembersController < Projects::ApplicationController
  include MembershipActions
  include MembersPresentation
  include SortingHelper

  # Authorize
  before_action :authorize_admin_project_member!, except: [:index, :leave, :request_access]

  feature_category :authentication_and_authorization

  def index
    @sort = params[:sort].presence || sort_value_name

    @skip_groups = @project.invited_group_ids
    @skip_groups += @project.group.self_and_ancestors_ids if @project.group

    @group_links = @project.project_group_links
    @group_links = @group_links.search(params[:search]) if params[:search].present?

    @project_members = MembersFinder
      .new(@project, current_user, params: filter_params)
      .execute(include_relations: requested_relations)

    @project_members = present_members(@project_members.page(params[:page]))

    @requesters = present_members(
      AccessRequestsFinder.new(@project).execute(current_user)
    )

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

    redirect_to(project_project_members_path(project), notice: notice)
  end

  # MembershipActions concern
  alias_method :membershipable, :project

  private

  def filter_params
    params.permit(:search).merge(sort: @sort)
  end

  def membershipable_members
    project.members
  end
end

Projects::ProjectMembersController.prepend_if_ee('EE::Projects::ProjectMembersController')
