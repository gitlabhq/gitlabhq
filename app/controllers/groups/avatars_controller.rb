# frozen_string_literal: true

class Groups::AvatarsController < Groups::ApplicationController
  before_action :authorize_admin_group!

  skip_cross_project_access_check :destroy

  feature_category :groups_and_projects

  def destroy
    @group.remove_avatar!
    @group.save

    redirect_to edit_group_path(@group), status: :found
  end
end
