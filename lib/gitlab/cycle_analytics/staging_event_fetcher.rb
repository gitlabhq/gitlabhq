# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class StagingEventFetcher < BaseEventFetcher
      include ProductionHelper
      include BuildsEventHelper
    end
  end
end
