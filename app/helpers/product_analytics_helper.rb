# frozen_string_literal: true

module ProductAnalyticsHelper
  def product_analytics_tracker_url
    ProductAnalytics::Tracker::URL
  end

  def product_analytics_tracker_collector_url
    ProductAnalytics::Tracker::COLLECTOR_URL
  end
end
