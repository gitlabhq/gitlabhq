# frozen_string_literal: true

module Projects
  class RefreshBuildArtifactsSizeStatisticsService
    BATCH_SIZE = 1000

    def execute
      refresh = Projects::BuildArtifactsSizeRefresh.process_next_refresh!

      return unless refresh&.running?

      batch = refresh.next_batch(limit: BATCH_SIZE).to_a

      if batch.any?
        increments = batch.map do |artifact|
          Gitlab::Counters::Increment.new(amount: artifact.size.to_i, ref: artifact.id)
        end

        Projects::BuildArtifactsSizeRefresh.transaction do
          # Mark the refresh ready for another worker to pick up and process the next batch
          refresh.requeue!(batch.last.id)

          ProjectStatistics.bulk_increment_statistic(refresh.project, :build_artifacts_size, increments)
        end
      else
        refresh.schedule_finalize!
      end

      refresh
    end
  end
end
