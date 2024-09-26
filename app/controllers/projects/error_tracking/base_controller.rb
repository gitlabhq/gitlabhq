# frozen_string_literal: true

class Projects::ErrorTracking::BaseController < Projects::ApplicationController
  POLLING_INTERVAL = 1_000

  feature_category :observability
  urgency :low

  def set_polling_interval
    Gitlab::PollingInterval.set_header(response, interval: POLLING_INTERVAL)
  end
end
