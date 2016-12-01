module Gitlab
  module CycleAnalytics
    module Stage
      def self.[](stage_name)
        const_get("::Gitlab::CycleAnalytics::#{stage_name.to_s.camelize}Stage")
      end
    end
  end
end
