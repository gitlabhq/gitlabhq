# frozen_string_literal: true

class Groups::GroupLinksController < Groups::ApplicationController
  before_action :check_feature_flag!
  before_action :authorize_admin_group!

  def create
    shared_with_group = Group.find(params[:shared_with_group_id]) if params[:shared_with_group_id].present?

    if shared_with_group
      result = Groups::GroupLinks::CreateService
                 .new(shared_with_group, current_user, group_link_create_params)
                 .execute(group)

      return render_404 if result[:http_status] == 404

      flash[:alert] = result[:message] if result[:status] == :error
    else
      flash[:alert] = _('Please select a group.')
    end

    redirect_to group_group_members_path(group)
  end

  private

  def group_link_create_params
    params.permit(:shared_group_access, :expires_at)
  end

  def check_feature_flag!
    render_404 unless Feature.enabled?(:share_group_with_group)
  end
end
