# frozen_string_literal: true

module MergeRequests
  # Performs the merge between source SHA and the target branch or the specified first parent ref. Instead
  # of writing the result to the MR target branch, it targets the `target_ref`.
  #
  # Ideally this should leave the `target_ref` state with the same state the
  # target branch would have if we used the regular `MergeService`, but without
  # every side-effect that comes with it (MR updates, mails, source branch
  # deletion, etc). This service should be kept idempotent (i.e. can
  # be executed regardless of the `target_ref` current state).
  #
  class MergeToRefService < MergeRequests::MergeBaseService
    extend ::Gitlab::Utils::Override

    def execute(merge_request, cache_merge_to_ref_calls = false)
      @merge_request = merge_request

      error_check!

      commit_id = commit(cache_merge_to_ref_calls)

      raise_error('Conflicts detected during merge') unless commit_id

      commit = project.commit(commit_id)
      target_id, source_id = commit.parent_ids

      success(commit_id: commit.id, target_id: target_id, source_id: source_id)
    rescue MergeError, ArgumentError => error
      error(error.message)
    end

    private

    override :source
    def source
      merge_request.diff_head_sha
    end

    override :error_check!
    def error_check!
      check_source
    end

    ##
    # The parameter `target_ref` is where the merge result will be written.
    # Default is the merge ref i.e. `refs/merge-requests/:iid/merge`.
    def target_ref
      params[:target_ref] || merge_request.merge_ref_path
    end

    ##
    # The parameter `first_parent_ref` is the main line of the merge commit.
    # Default is the target branch ref of the merge request.
    def first_parent_ref
      params[:first_parent_ref] || merge_request.target_branch_ref
    end

    ##
    # The parameter `allow_conflicts` is a flag whether merge conflicts should be merged into diff
    # Default is false
    def allow_conflicts
      params[:allow_conflicts] || false
    end

    def commit(cache_merge_to_ref_calls = false)
      if cache_merge_to_ref_calls
        Rails.cache.fetch(cache_key, expires_in: 1.day) do
          extracted_merge_to_ref
        end
      else
        extracted_merge_to_ref
      end
    end

    def extracted_merge_to_ref
      repository.merge_to_ref(current_user,
        source_sha: source,
        branch: merge_request.target_branch,
        target_ref: target_ref,
        message: commit_message,
        first_parent_ref: first_parent_ref,
        allow_conflicts: allow_conflicts)
    rescue Gitlab::Git::PreReceiveError, Gitlab::Git::CommandError => error
      raise MergeError, error.message
    end

    def cache_key
      [:merge_to_ref_service, project.full_path, merge_request.target_branch_sha, merge_request.source_branch_sha]
    end
  end
end
