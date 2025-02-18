# frozen_string_literal: true

class MergeRequestCleanupRefsWorker
  include ApplicationWorker
  include CronjobChildWorker
  include LimitedCapacity::Worker
  include Gitlab::Utils::StrongMemoize

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :code_review_workflow
  idempotent!

  # Hard-coded to 4 for now. Will be configurable later on via application settings.
  # This means, there can only be 4 jobs running at the same time at maximum.
  MAX_RUNNING_JOBS = 4
  FAILURE_THRESHOLD = 3

  def perform_work
    unless merge_request
      logger.info('No existing merge request to be cleaned up.')
      return
    end

    log_extra_metadata_on_done(:merge_request_id, merge_request.id)

    result = MergeRequests::CleanupRefsService.new(merge_request).execute

    if result[:status] == :success
      merge_request_cleanup_schedule.complete!
    else
      if merge_request_cleanup_schedule.failed_count < FAILURE_THRESHOLD
        merge_request_cleanup_schedule.retry!
      else
        merge_request_cleanup_schedule.mark_as_failed!
      end

      log_extra_metadata_on_done(:message, result[:message])
    end

    log_extra_metadata_on_done(:status, merge_request_cleanup_schedule.status)
  end

  def remaining_work_count
    MergeRequest::CleanupSchedule
      .scheduled_and_unstarted
      .limit(max_running_jobs)
      .count
  end

  def max_running_jobs
    MAX_RUNNING_JOBS
  end

  private

  def merge_request
    strong_memoize(:merge_request) do
      merge_request_cleanup_schedule&.merge_request
    end
  end

  def merge_request_cleanup_schedule
    strong_memoize(:merge_request_cleanup_schedule) do
      MergeRequest::CleanupSchedule.start_next
    end
  end
end
