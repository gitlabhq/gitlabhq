# frozen_string_literal: true

# rubocop:disable Scalability/IdempotentWorker
class StuckExportJobsWorker
  include ApplicationWorker

  data_consistency :always

  # rubocop:disable Scalability/CronWorkerContext
  # This worker updates export states inline and does not schedule
  # other jobs.
  include CronjobQueue
  # rubocop:enable Scalability/CronWorkerContext

  feature_category :importers
  worker_resource_boundary :cpu

  EXPORT_JOBS_EXPIRATION = 6.hours.to_i

  def perform
    failed_jobs_count = mark_stuck_jobs_as_failed!

    Gitlab::Metrics.add_event(:stuck_export_jobs, failed_jobs_count: failed_jobs_count)
  end

  private

  # rubocop: disable CodeReuse/ActiveRecord
  def mark_stuck_jobs_as_failed!
    jids_and_ids = enqueued_exports.pluck(:jid, :id).to_h

    completed_jids = Gitlab::SidekiqStatus.completed_jids(jids_and_ids.keys)
    return unless completed_jids.any?

    completed_ids = jids_and_ids.values_at(*completed_jids)

    # We select the export states again, because they may have transitioned from
    # started to finished while we were looking up their Sidekiq status.
    completed_jobs = enqueued_exports.where(id: completed_ids)

    Sidekiq.logger.info(
      message: 'Marked stuck export jobs as failed',
      job_ids: completed_jobs.map(&:jid)
    )

    completed_jobs.each do |job|
      # Parallel export job completes and keeps 'started' state because it has
      # multiple relation exports running in parallel. Don't mark it as failed
      # until 6 hours mark
      next if job.relation_exports.any? && job.created_at > EXPORT_JOBS_EXPIRATION.seconds.ago

      job.fail_op
    end.count
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def enqueued_exports
    ProjectExportJob.with_status([:started, :queued])
  end
end
# rubocop:enable Scalability/IdempotentWorker
