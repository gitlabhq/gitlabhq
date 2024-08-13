# frozen_string_literal: true

class Groups::GroupLinksController < Groups::ApplicationController
  before_action :authorize_admin_group!
  before_action :group_link, only: [:update, :destroy]

  feature_category :groups_and_projects

  def update
    Groups::GroupLinks::UpdateService.new(@group_link, current_user).execute(group_link_params)

    if @group_link.expires?
      render json: {
        expires_in: helpers.time_ago_with_tooltip(@group_link.expires_at),
        expires_soon: @group_link.expires_soon?
      }
    else
      render json: {}
    end
  end

  def destroy
    Groups::GroupLinks::DestroyService.new(group, current_user).execute(@group_link)

    respond_to do |format|
      format.html do
        redirect_to group_group_members_path(group), status: :found
      end
      format.js { head :ok }
    end
  end

  private

  def group_link
    @group_link ||= group.shared_with_group_links.find(params[:id])
  end

  def group_link_params
    params.require(:group_link).permit(:group_access, :expires_at, :member_role_id)
  end
end
