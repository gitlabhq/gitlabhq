# frozen_string_literal: true

module Users
  class ProjectCalloutsController < Users::CalloutsController
    private

    def callout
      Users::DismissProjectCalloutService.new(
        container: nil, current_user: current_user, params: callout_params
      ).execute
    end

    def callout_params
      params.permit(:project_id).merge(feature_name: feature_name)
    end
  end
end
