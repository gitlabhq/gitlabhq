# frozen_string_literal: true

module MergeRequests
  class CleanupRefsService
    include BaseServiceUtility

    TIME_THRESHOLD = 14.days

    attr_reader :merge_request

    def self.schedule(merge_request)
      merge_request.create_cleanup_schedule(scheduled_at: TIME_THRESHOLD.from_now)
    end

    def initialize(merge_request)
      @merge_request = merge_request
      @repository = merge_request.project.repository
      @ref_path = merge_request.ref_path
      @ref_head_sha = @repository.commit(merge_request.ref_path)&.id
      @merge_ref_sha = merge_request.merge_ref_head&.id
    end

    def execute
      return error("Merge request is not scheduled to be cleaned up yet.") unless scheduled?
      return error("Merge request has not been closed nor merged for #{TIME_THRESHOLD.inspect}.") unless eligible?

      return error('Failed to cache merge ref sha.') unless cache_merge_ref_sha

      delete_refs if repository.exists?

      return error('Failed to update schedule.') unless update_schedule

      success
    rescue Gitlab::Git::Repository::GitError, Gitlab::Git::CommandError => e
      error(e.message)
    end

    private

    attr_reader :repository, :ref_path, :ref_head_sha, :merge_ref_sha

    def scheduled?
      merge_request.cleanup_schedule.present? && merge_request.cleanup_schedule.scheduled_at <= Time.current
    end

    def eligible?
      return met_time_threshold?(merge_request.metrics&.latest_closed_at) if merge_request.closed?

      merge_request.merged? && met_time_threshold?(merge_request.metrics&.merged_at)
    end

    def met_time_threshold?(attr)
      attr.nil? || attr.to_i <= TIME_THRESHOLD.ago.to_i
    end

    def cache_merge_ref_sha
      return true if merge_ref_sha.nil?

      # Caching the merge ref sha is needed before we delete the merge ref so
      # we can still show the merge ref diff (via `MergeRequest#merge_ref_head`)
      merge_request.update_column(:merge_ref_sha, merge_ref_sha)
    end

    def delete_refs
      merge_request.schedule_cleanup_refs
    end

    def update_schedule
      merge_request.cleanup_schedule.update(completed_at: Time.current)
    end
  end
end
