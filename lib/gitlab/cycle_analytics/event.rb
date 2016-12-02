module Gitlab
  module CycleAnalytics
    module Event
      def self.[](stage_name)
        CycleAnalytics.const_get("#{stage_name.to_s.camelize}Event")
      end
    end
  end
end
