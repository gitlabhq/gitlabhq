# frozen_string_literal: true

module UserSettings
  class UserSettingsController < ApplicationController
    feature_category :system_access

    def authentication_log
      @events = AuthenticationEvent.for_user(current_user)
          .order_by_created_at_desc
          .page(pagination_params[:page])

      Gitlab::Tracking.event(self.class.name, 'search_audit_event', user: current_user)
    end
  end
end
