# frozen_string_literal: true

module MergeRequests
  class MergeabilityCheckService < ::BaseService
    include Gitlab::Utils::StrongMemoize
    include Gitlab::ExclusiveLeaseHelpers

    delegate :project, to: :@merge_request
    delegate :repository, to: :project

    def initialize(merge_request)
      @merge_request = merge_request
    end

    # Updates the MR merge_status. Whenever it switches to a can_be_merged state,
    # the merge-ref is refreshed.
    #
    # recheck - When given, it'll enforce a merge-ref refresh if the current merge_status is
    # can_be_merged or cannot_be_merged and merge-ref is outdated.
    # Given MergeRequests::RefreshService is called async, it might happen that the target
    # branch gets updated, but the MergeRequest#merge_status lags behind. So in scenarios
    # where we need the current state of the merge ref in repository, the `recheck`
    # argument is required.
    #
    # retry_lease - Concurrent calls wait for at least 10 seconds until the
    # lease is granted (other process finishes running). Returns an error
    # ServiceResponse if the lease is not granted during this time.
    #
    # Returns a ServiceResponse indicating merge_status is/became can_be_merged
    # and the merge-ref is synced. Success in case of being/becoming mergeable,
    # error otherwise.
    def execute(recheck: false, retry_lease: true)
      return ServiceResponse.error(message: 'Invalid argument') unless merge_request
      return ServiceResponse.error(message: 'Unsupported operation') if Gitlab::Database.read_only?
      return check_mergeability(recheck) unless merge_ref_auto_sync_lock_enabled?

      in_write_lock(retry_lease: retry_lease) do |retried|
        # When multiple calls are waiting for the same lock (retry_lease),
        # it's possible that when granted, the MR status was already updated for
        # that object, therefore we reset if there was a lease retry.
        merge_request.reset if retried

        check_mergeability(recheck)
      end
    rescue FailedToObtainLockError => error
      ServiceResponse.error(message: error.message)
    end

    private

    attr_reader :merge_request

    def check_mergeability(recheck)
      recheck! if recheck
      update_merge_status

      unless merge_request.can_be_merged?
        return ServiceResponse.error(message: 'Merge request is not mergeable')
      end

      unless merge_ref_auto_sync_enabled?
        return ServiceResponse.error(message: 'Merge ref is outdated due to disabled feature')
      end

      unless payload.fetch(:merge_ref_head)
        return ServiceResponse.error(message: 'Merge ref cannot be updated')
      end

      ServiceResponse.success(payload: payload)
    end

    # It's possible for this service to send concurrent requests to Gitaly in order
    # to "git update-ref" the same ref. Therefore we handle a light exclusive
    # lease here.
    #
    def in_write_lock(retry_lease:, &block)
      lease_key = "mergeability_check:#{merge_request.id}"

      lease_opts = {
        ttl:       1.minute,
        retries:   retry_lease ? 10 : 0,
        sleep_sec: retry_lease ? 1.second : 0
      }

      in_lock(lease_key, lease_opts, &block)
    end

    def payload
      strong_memoize(:payload) do
        {
          merge_ref_head: merge_ref_head_payload
        }
      end
    end

    def merge_ref_head_payload
      commit = merge_request.merge_ref_head

      return unless commit

      target_id, source_id = commit.parent_ids

      {
        commit_id: commit.id,
        source_id: source_id,
        target_id: target_id
      }
    end

    def update_merge_status
      return unless merge_request.recheck_merge_status?

      if can_git_merge? && merge_to_ref
        merge_request.mark_as_mergeable
      else
        merge_request.mark_as_unmergeable
      end
    end

    def recheck!
      if !merge_request.recheck_merge_status? && outdated_merge_ref?
        merge_request.mark_as_unchecked
      end
    end

    # Checks if the existing merge-ref is synced with the target branch.
    #
    # Returns true if the merge-ref does not exists or is out of sync.
    def outdated_merge_ref?
      return false unless merge_ref_auto_sync_enabled?
      return false unless merge_request.open?

      return true unless ref_head = merge_request.merge_ref_head
      return true unless target_sha = merge_request.target_branch_sha
      return true unless source_sha = merge_request.source_branch_sha

      ref_head.parent_ids != [target_sha, source_sha]
    end

    def can_git_merge?
      !merge_request.broken? && repository.can_be_merged?(merge_request.diff_head_sha, merge_request.target_branch)
    end

    def merge_to_ref
      return true unless merge_ref_auto_sync_enabled?

      result = MergeRequests::MergeToRefService.new(project, merge_request.author).execute(merge_request)
      result[:status] == :success
    end

    def merge_ref_auto_sync_enabled?
      Feature.enabled?(:merge_ref_auto_sync, project, default_enabled: true)
    end

    def merge_ref_auto_sync_lock_enabled?
      Feature.enabled?(:merge_ref_auto_sync_lock, project, default_enabled: true)
    end
  end
end
