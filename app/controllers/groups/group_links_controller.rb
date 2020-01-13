# frozen_string_literal: true

class Groups::GroupLinksController < Groups::ApplicationController
  before_action :check_feature_flag!
  before_action :authorize_admin_group!
  before_action :group_link, only: [:update, :destroy]

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

  def update
    @group_link.update(group_link_params)
  end

  def destroy
    Groups::GroupLinks::DestroyService.new(nil, nil).execute(@group_link)

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

  def group_link_create_params
    params.permit(:shared_group_access, :expires_at)
  end

  def group_link_params
    params.require(:group_link).permit(:group_access, :expires_at)
  end

  def check_feature_flag!
    render_404 unless Feature.enabled?(:share_group_with_group)
  end
end
