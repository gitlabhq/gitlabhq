module Gitlab
  module CycleAnalytics
    module Event
      def self.[](stage_name)
        const_get("::Gitlab::CycleAnalytics::#{stage_name.to_s.camelize}Event")
      end
    end
  end
end
