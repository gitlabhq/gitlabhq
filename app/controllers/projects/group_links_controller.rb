# frozen_string_literal: true

class Projects::GroupLinksController < Projects::ApplicationController
  layout 'project_settings'
  before_action :authorize_admin_project!
  before_action :authorize_admin_project_member!, only: [:update]

  feature_category :subgroups

  def update
    group_link = @project.project_group_links.find(params[:id])
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
    group_link = project.project_group_links.find(params[:id])

    ::Projects::GroupLinks::DestroyService.new(project, current_user).execute(group_link)

    respond_to do |format|
      format.html do
        redirect_to project_project_members_path(project), status: :found
      end
      format.js { head :ok }
    end
  end

  protected

  def group_link_params
    params.require(:group_link).permit(:group_access, :expires_at)
  end
end
