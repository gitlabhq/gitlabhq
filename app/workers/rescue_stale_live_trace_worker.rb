class RescueStaleLiveTraceWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    # Reschedule to archive live traces
    #
    # The targets are jobs with the following conditions
    # - It had been finished 1 hour ago, but it has not had an acthived trace yet
    #   This case happens when sidekiq-jobs of archiving traces are lost in order to restart sidekiq instace which hit RSS limit
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
