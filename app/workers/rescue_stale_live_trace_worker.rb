class RescueStaleLiveTraceWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    # Reschedule to archive live traces
    #
    # The target jobs are with the following conditions
    # - Finished 1 hour ago, but it has not had an acthived trace yet
    #   Jobs finished 1 hour ago should have an archived trace. Probably ArchiveTraceWorker failed by Sidekiq's inconsistancy
    Ci::BuildTraceChunk
      .include(EachBatch)
      .select(:build_id)
      .group(:build_id)
      .joins(:build)
      .merge(Ci::Build.finished)
      .where('ci_builds.finished_at < ?', 1.hour.ago)
      .each_batch(column: :build_id) do |chunks|
        build_ids = chunks.map { |chunk| [chunk.build_id] }

        ArchiveTraceWorker.bulk_perform_async(build_ids)

        Rails.logger.info "Scheduled to archive stale live traces from #{build_ids.min} to #{build_ids.max}"
      end
  end
end
