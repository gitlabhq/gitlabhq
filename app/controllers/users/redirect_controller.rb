# frozen_string_literal: true

module Users
  class RedirectController < ::ApplicationController
    skip_before_action :authenticate_user!

    feature_category :user_management

    def redirect_from_id
      # Unauthenticated users will receive a HTTP 403 Forbidden, matching the behavior in the Users API
      if current_user
        user = User.find(user_params[:id])
        redirect_to user
      else
        render_403
      end
    end

    private

    def user_params
      params.permit(:id)
    end
  end
end
