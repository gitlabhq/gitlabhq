# frozen_string_literal: true

module Users
  class DismissGroupCalloutService < DismissUserCalloutService
    private

    def callout
      current_user.find_or_initialize_group_callout(params[:feature_name], params[:group_id])
    end
  end
end
