# frozen_string_literal: true

module Users
  class GroupCalloutsController < Users::CalloutsController
    private

    def callout
      Users::DismissGroupCalloutService.new(
        container: nil, current_user: current_user, params: callout_params
      ).execute
    end

    def callout_params
      params.permit(:group_id).merge(feature_name: feature_name)
    end
  end
end
