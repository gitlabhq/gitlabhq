module Gitlab
  module CycleAnalytics
    class BuildUpdater < Updater
      def self.update!(event_result)
        new(event_result, ::Ci::Build, :build, 'id').update!
      end
    end
  end
end
