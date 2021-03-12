# frozen_string_literal: true

module Users
  class DismissUserCalloutService < BaseContainerService
    def execute
      current_user.find_or_initialize_callout(params[:feature_name]).tap do |callout|
        callout.update(dismissed_at: Time.current) if callout.valid?
      end
    end
  end
end
