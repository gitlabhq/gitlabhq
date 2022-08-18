# frozen_string_literal: true

module Users
  class DismissProjectCalloutService < DismissCalloutService
    private

    def callout
      current_user.find_or_initialize_project_callout(params[:feature_name], params[:project_id])
    end
  end
end
