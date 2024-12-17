# frozen_string_literal: true

class Projects::GroupLinksController < Projects::ApplicationController
  layout 'project_settings'
  before_action :authorize_admin_project!, except: [:destroy]
  before_action :authorize_manage_destroy!, only: [:destroy]
  before_action :authorize_admin_project_member!, only: [:update]

  feature_category :groups_and_projects

  def update
    result = Projects::GroupLinks::UpdateService.new(group_link, current_user).execute(group_link_params)

    if result.success?
      if group_link.expires?
        render json: {
          expires_in: helpers.time_ago_with_tooltip(group_link.expires_at),
          expires_soon: group_link.expires_soon?
        }
      else
        render json: {}
      end
    else
      render json: { message: result.message }, status: result.reason
    end
  end

  def destroy
    result = ::Projects::GroupLinks::DestroyService.new(project, current_user).execute(group_link)

    if result.success?
      respond_to do |format|
        format.html do
          if can?(current_user, :admin_group, group_link.group)
            redirect_to group_path(group_link.group), status: :found
          elsif can?(current_user, :admin_project, group_link.project)
            redirect_to project_project_members_path(project), status: :found
          end
        end
        format.js { head :ok }
      end
    else
      respond_to do |format|
        format.html do
          redirect_to project_project_members_path(project, tab: :groups), status: :found,
            alert: _('The project-group link could not be removed.')
        end

        format.js do
          render json: { message: result.message }, status: result.reason
        end
      end
    end
  end

  protected

  def authorize_manage_destroy!
    render_404 unless can?(current_user, :manage_destroy, group_link)
  end

  def group_link
    @project.project_group_links.find(params[:id])
  end
  strong_memoize_attr :group_link

  def group_link_params
    params.require(:group_link).permit(:group_access, :expires_at, :member_role_id)
  end
end
