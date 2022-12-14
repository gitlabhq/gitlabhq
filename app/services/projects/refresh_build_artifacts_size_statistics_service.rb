# frozen_string_literal: true

module Projects
  class RefreshBuildArtifactsSizeStatisticsService
    BATCH_SIZE = 1000

    def execute
      refresh = Projects::BuildArtifactsSizeRefresh.process_next_refresh!
      return unless refresh

      batch = refresh.next_batch(limit: BATCH_SIZE).to_a

      if batch.any?
        # We are doing the sum in ruby because the query takes too long when done in SQL
        total_artifacts_size = batch.sum { |artifact| artifact.size.to_i }

        Projects::BuildArtifactsSizeRefresh.transaction do
          # Mark the refresh ready for another worker to pick up and process the next batch
          refresh.requeue!(batch.last.id)

          refresh.project.statistics.increment_counter(:build_artifacts_size, total_artifacts_size)
        end
      else
        # Remove the refresh job from the table if there are no more
        # remaining job artifacts to calculate for the given project.
        refresh.destroy!
      end

      refresh
    end
  end
end
