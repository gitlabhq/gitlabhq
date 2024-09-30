# frozen_string_literal: true

module Groups
  class RedirectController < ::ApplicationController
    skip_before_action :authenticate_user!

    feature_category :groups_and_projects

    def redirect_from_id
      group = Group.find(group_params[:id])

      if can?(current_user, :read_group, group)
        redirect_to group
      else
        render_404
      end
    end

    private

    def group_params
      params.permit(:id)
    end
  end
end
