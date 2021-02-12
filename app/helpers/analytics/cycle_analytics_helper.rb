# frozen_string_literal: true

module Analytics
  module CycleAnalyticsHelper
    def cycle_analytics_default_stage_config
      Gitlab::Analytics::CycleAnalytics::DefaultStages.all.map do |stage_params|
        Analytics::CycleAnalytics::StagePresenter.new(stage_params)
      end
    end
  end
end
