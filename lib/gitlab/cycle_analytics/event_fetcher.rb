# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module EventFetcher
      def self.[](stage_name)
        CycleAnalytics.const_get("#{stage_name.to_s.camelize}EventFetcher", false)
      end
    end
  end
end
