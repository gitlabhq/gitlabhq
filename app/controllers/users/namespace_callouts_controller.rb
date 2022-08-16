# frozen_string_literal: true

module Users
  class NamespaceCalloutsController < Users::CalloutsController
    private

    def callout
      Users::DismissNamespaceCalloutService.new(
        container: nil, current_user: current_user, params: callout_params
      ).execute
    end

    def callout_params
      params.permit(:namespace_id).merge(feature_name: feature_name)
    end
  end
end
