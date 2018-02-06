module Gitlab
  module CycleAnalytics
    module Stage
      def self.[](stage_name)
        CycleAnalytics.const_get("#{stage_name.to_s.camelize}Stage")
      end
    end
  end
end
