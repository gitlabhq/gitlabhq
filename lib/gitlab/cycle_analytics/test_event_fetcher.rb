# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class TestEventFetcher < BaseEventFetcher
      include TestHelper
      include BuildsEventHelper
    end
  end
end
