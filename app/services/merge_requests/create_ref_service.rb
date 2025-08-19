# frozen_string_literal: true

module MergeRequests
  # CreateRefService creates or overwrites a ref under "refs/merge-requests/"
  # with a commit for the merged result.
  class CreateRefService
    include Gitlab::Utils::StrongMemoize

    CreateRefError = Class.new(StandardError)

    def initialize(
      current_user:, merge_request:, target_ref:, first_parent_ref:, source_sha: nil, merge_params: {}
    )
      @current_user = current_user
      @merge_request = merge_request
      @source_sha = source_sha
      @target_ref = target_ref
      @first_parent_ref = first_parent_ref
      @first_parent_sha = target_project.commit(first_parent_ref)&.sha
      @merge_params = merge_params
    end

    def execute
      # The "3:" prefix is for compatibility with the output of
      # MergeToRefService, which is still used to create merge refs and some
      # merge train refs. The prefix can be dropped once MergeToRefService is no
      # longer used. See https://gitlab.com/gitlab-org/gitlab/-/issues/455421
      # and https://gitlab.com/gitlab-org/gitlab/-/issues/421025
      return ServiceResponse.error(message: '3:Invalid merge source') unless first_parent_sha.present?

      result = {
        commit_sha: source_sha,      # the SHA to be at HEAD of target_ref
        expected_old_oid: "",        # the SHA we expect target_ref to be at prior to an update (an optimistic lock)
        source_sha: source_sha,      # for pipeline.source_sha
        target_sha: first_parent_sha # for pipeline.target_sha
      }

      result = maybe_squash!(**result)
      result = maybe_rebase!(**result)
      result = maybe_merge!(**result)

      # Store generated ref commits if conditions are met
      store_generated_ref_commits_if_needed(result[:commit_sha])

      ServiceResponse.success(payload: result)
    rescue CreateRefError => error
      ServiceResponse.error(message: error.message)
    end

    private

    def store_generated_ref_commits_if_needed(final_commit_sha)
      return unless should_store_generated_ref_commits?

      store_generated_ref_commits(final_commit_sha)
    end

    # Default CE implementation - can be overridden in EE
    def should_store_generated_ref_commits?
      false # only available in ee for merge trains for now
    end

    attr_reader :current_user, :merge_request, :target_ref, :first_parent_ref, :first_parent_sha, :source_sha,
      :merge_params

    delegate :target_project, to: :merge_request
    delegate :repository, to: :target_project

    def store_generated_ref_commits(final_commit_sha)
      commit_shas = commit_shas_between_refs(final_commit_sha, limit: 500)
      return unless commit_shas.any?

      GeneratedRefCommit.transaction do
        # Prepare records for bulk insert
        records = commit_shas.map do |commit_sha|
          {
            merge_request_iid: merge_request.iid,
            commit_sha: commit_sha,
            project_id: merge_request.project_id,
            created_at: Time.current,
            updated_at: Time.current
          }
        end
        GeneratedRefCommit.upsert_all(records, unique_by: [:id, :project_id])
      end
    rescue ::PG::Error => e
      # Log error but don't break the main flow
      Gitlab::AppLogger.error("Failed to store generated ref commits for MR #{merge_request.id}: #{e.message}")
    end

    def commits_between_refs(final_commit_sha, limit: nil)
      return [] unless final_commit_sha && first_parent_sha

      safe_gitaly_operation do
        repository.commits_between(first_parent_sha, final_commit_sha, limit: limit)
      end
    end

    def commit_shas_between_refs(final_commit_sha, limit: nil)
      commits_between_refs(final_commit_sha, limit: limit).map(&:sha)
    end

    def maybe_squash!(commit_sha:, **rest)
      if merge_request.squash_on_merge?
        squash_result = MergeRequests::SquashService.new(
          merge_request: merge_request,
          current_user: current_user,
          commit_message: squash_commit_message
        ).execute

        raise CreateRefError, squash_result[:message] if squash_result[:status] == :error

        commit_sha = squash_result[:squash_sha]
        squash_commit_sha = commit_sha
      end

      # squash does not overwrite target_ref, so expected_old_oid remains the same
      rest.merge(
        commit_sha: commit_sha,
        squash_commit_sha: squash_commit_sha
      ).compact
    end

    def maybe_rebase!(commit_sha:, expected_old_oid:, squash_commit_sha: nil, **rest)
      if target_project.ff_merge_must_be_possible?
        commit_sha = safe_gitaly_operation do
          repository.rebase_to_ref(
            current_user,
            source_sha: commit_sha,
            target_ref: target_ref,
            first_parent_ref: first_parent_sha,
            expected_old_oid: expected_old_oid || ""
          )
        end

        squash_commit_sha = commit_sha if squash_commit_sha # rebase rewrites commit SHAs after first_parent_sha
        expected_old_oid = commit_sha
      end

      rest.merge(
        commit_sha: commit_sha,
        squash_commit_sha: squash_commit_sha,
        expected_old_oid: expected_old_oid
      ).compact
    end

    def maybe_merge!(commit_sha:, expected_old_oid:, **rest)
      unless target_project.merge_requests_ff_only_enabled
        commit_sha = safe_gitaly_operation do
          repository.merge_to_ref(
            current_user,
            source_sha: commit_sha,
            target_ref: target_ref,
            message: merge_commit_message,
            first_parent_ref: first_parent_sha,
            branch: nil,
            expected_old_oid: expected_old_oid || ""
          )
        end

        expected_old_oid = commit_sha
        merge_commit_sha = commit_sha
      end

      rest.merge(
        commit_sha: commit_sha,
        merge_commit_sha: merge_commit_sha,
        expected_old_oid: expected_old_oid
      ).compact
    end

    def safe_gitaly_operation
      yield
    rescue Gitlab::Git::PreReceiveError, Gitlab::Git::CommandError, ArgumentError => error
      raise CreateRefError, error.message
    end

    def squash_commit_message
      # We priotize the merge params passed in take presendence
      merge_params['squash_commit_message'].presence ||
        merge_request.merge_params['squash_commit_message'].presence ||
        merge_request.default_squash_commit_message(user: current_user)
    end
    strong_memoize_attr :squash_commit_message

    def merge_commit_message
      # We priotize the merge params passed in take presendence
      merge_params['commit_message'].presence ||
        merge_request.merge_params['commit_message'].presence ||
        merge_request.default_merge_commit_message(user: current_user)
    end
  end
end

MergeRequests::CreateRefService.prepend_mod_with('MergeRequests::CreateRefService')
