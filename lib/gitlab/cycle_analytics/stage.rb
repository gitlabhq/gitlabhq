# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module Stage
      def self.[](stage_name)
        CycleAnalytics.const_get("#{stage_name.to_s.camelize}Stage", false)
      end
    end
  end
end
