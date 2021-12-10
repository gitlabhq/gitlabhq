# frozen_string_literal: true

module Users
  class DismissCalloutService < BaseContainerService
    def execute
      callout.tap do |record|
        record.update(dismissed_at: Time.current) if record.valid?
      end
    end

    private

    def callout
      current_user.find_or_initialize_callout(params[:feature_name])
    end
  end
end
