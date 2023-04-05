# frozen_string_literal: true

module TimeTracking
  class TimelogsController < ApplicationController
    feature_category :team_planning
    urgency :low

    def index
      render_404 unless Feature.enabled?(:global_time_tracking_report, current_user)
    end
  end
end
