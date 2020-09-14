# frozen_string_literal: true

module ProductAnalytics
  class BuildActivityGraphService < BuildGraphService
    def execute
      timerange = @params[:timerange].days

      results = product_analytics_events.count_collector_tstamp_by_day(timerange)

      format_results('collector_tstamp', results.transform_keys(&:to_date))
    end
  end
end
