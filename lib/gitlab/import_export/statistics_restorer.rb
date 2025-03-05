# frozen_string_literal: true

module Gitlab
  module ImportExport
    class StatisticsRestorer
      include ::Import::Framework::ProgressTracking

      attr_reader :project

      def initialize(project:, shared:)
        @project = project
        @shared = shared
      end

      def restore
        with_progress_tracking(**progress_tracking_options) do
          @project.statistics.refresh!
        end
      rescue StandardError => e
        @shared.error(e)
        false
      end

      private

      def progress_tracking_options
        {
          scope: {
            project_id: project.id
          },
          data: 'statistics_refresh'
        }
      end
    end
  end
end
