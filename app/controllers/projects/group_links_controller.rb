# frozen_string_literal: true

class Projects::GroupLinksController < Projects::ApplicationController
  layout 'project_settings'
  before_action :authorize_admin_project!, except: [:destroy]
  before_action :authorize_admin_project_group_link!, only: [:destroy]
  before_action :authorize_admin_project_member!, only: [:update]

  feature_category :subgroups

  def update
    Projects::GroupLinks::UpdateService.new(group_link, current_user).execute(group_link_params)

    if group_link.expires?
      render json: {
        expires_in: helpers.time_ago_with_tooltip(group_link.expires_at),
        expires_soon: group_link.expires_soon?
      }
    else
      render json: {}
    end
  end

  def destroy
    ::Projects::GroupLinks::DestroyService.new(project, current_user).execute(group_link)

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
  end

  protected

  def authorize_admin_project_group_link!
    render_404 unless can?(current_user, :admin_project_group_link, group_link)
  end

  def group_link
    @project.project_group_links.find(params[:id])
  end
  strong_memoize_attr :group_link

  def group_link_params
    params.require(:group_link).permit(:group_access, :expires_at)
  end
end
