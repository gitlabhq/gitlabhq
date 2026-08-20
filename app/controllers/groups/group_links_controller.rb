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
    result = Groups::GroupLinks::DestroyService.new(group, current_user).execute(@group_link)
    error = result.is_a?(Hash) && result[:status] == :error

    respond_to do |format|
      format.html do
        if error
          redirect_to(
            group_group_members_path(group),
            status: :found,
            alert: _('The group link could not be removed.')
          )
        else
          redirect_to(
            group_group_members_path(group),
            status: :found,
            notice: s_('InviteMembersModal|Group invite removed. ' \
              'It might take a few minutes for the changes to user access levels to take effect.')
          )
        end
      end
      format.js { head(error ? :not_found : :ok) }
    end
  end

  private

  def group_link
    @group_link ||= group.shared_with_group_links.find(params.permit(:id)[:id])
  end

  def group_link_params
    params.require(:group_link).permit(:group_access, :expires_at, :member_role_id)
  end
end
