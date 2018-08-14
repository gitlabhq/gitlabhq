module Gitlab
  module ImportExport
    class StatisticsRestorer
      def initialize(project:, shared:)
        @project = project
        @shared = shared
      end

      def restore
        @project.statistics.refresh!
      rescue => e
        @shared.error(e)
        false
      end
    end
  end
end
