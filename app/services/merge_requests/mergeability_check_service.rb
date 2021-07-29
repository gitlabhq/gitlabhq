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

    def async_execute
      return service_error if service_error
      return unless merge_request.mark_as_checking

      MergeRequestMergeabilityCheckWorker.perform_async(merge_request.id)
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
      return service_error if service_error

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

      in_lock(lease_key, **lease_opts, &block)
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
      return merge_request.mark_as_unmergeable if merge_request.broken?

      merge_to_ref_success = merge_to_ref

      reload_merge_head_diff
      update_diff_discussion_positions! if merge_to_ref_success

      if merge_to_ref_success && can_git_merge?
        merge_request.mark_as_mergeable
      else
        merge_request.mark_as_unmergeable
      end
    end

    def reload_merge_head_diff
      MergeRequests::ReloadMergeHeadDiffService.new(merge_request).execute
    end

    def update_diff_discussion_positions!
      Discussions::CaptureDiffNotePositionsService.new(merge_request).execute
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
      return false unless merge_request.open?

      return true unless ref_head = merge_request.merge_ref_head
      return true unless target_sha = merge_request.target_branch_sha
      return true unless source_sha = merge_request.source_branch_sha

      ref_head.parent_ids != [target_sha, source_sha]
    end

    def can_git_merge?
      repository.can_be_merged?(merge_request.diff_head_sha, merge_request.target_branch)
    end

    def merge_to_ref
      params = { allow_conflicts: Feature.enabled?(:display_merge_conflicts_in_diff, project) }
      result = MergeRequests::MergeToRefService.new(project: project, current_user: merge_request.author, params: params).execute(merge_request)

      result[:status] == :success
    end

    def service_error
      strong_memoize(:service_error) do
        if !merge_request
          ServiceResponse.error(message: 'Invalid argument')
        elsif Gitlab::Database.main.read_only?
          ServiceResponse.error(message: 'Unsupported operation')
        end
      end
    end
  end
end
