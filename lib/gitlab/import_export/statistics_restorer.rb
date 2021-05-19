# frozen_string_literal: true

module Gitlab
  module ImportExport
    class StatisticsRestorer
      def initialize(project:, shared:)
        @project = project
        @shared = shared
      end

      def restore
        @project.statistics.refresh!
      rescue StandardError => e
        @shared.error(e)
        false
      end
    end
  end
end
