# frozen_string_literal: true

module Git
  class BranchHooksService < ::Git::BaseHooksService
    def execute
      execute_branch_hooks

      super.tap do
        enqueue_update_gpg_signatures
      end
    end

    private

    def hook_name
      :push_hooks
    end

    def commits
      strong_memoize(:commits) do
        if creating_default_branch?
          # The most recent PROCESS_COMMIT_LIMIT commits in the default branch
          project.repository.commits(params[:newrev], limit: PROCESS_COMMIT_LIMIT)
        elsif creating_branch?
          # Use the pushed commits that aren't reachable by the default branch
          # as a heuristic. This may include more commits than are actually
          # pushed, but that shouldn't matter because we check for existing
          # cross-references later.
          project.repository.commits_between(project.default_branch, params[:newrev])
        elsif updating_branch?
          project.repository.commits_between(params[:oldrev], params[:newrev])
        else # removing branch
          []
        end
      end
    end

    def commits_count
      return count_commits_in_branch if creating_default_branch?

      super
    end

    def invalidated_file_types
      return super unless default_branch? && !creating_branch?

      paths = limited_commits.each_with_object(Set.new) do |commit, set|
        commit.raw_deltas.each do |diff|
          set << diff.new_path
        end
      end

      Gitlab::FileDetector.types_in_paths(paths)
    end

    def execute_branch_hooks
      project.repository.after_push_commit(branch_name)

      branch_create_hooks if creating_branch?
      branch_update_hooks if updating_branch?
      branch_change_hooks if creating_branch? || updating_branch?
      branch_remove_hooks if removing_branch?
    end

    def branch_create_hooks
      project.repository.after_create_branch(expire_cache: false)
      project.after_create_default_branch if default_branch?
    end

    def branch_update_hooks
      # Update the bare repositories info/attributes file using the contents of
      # the default branch's .gitattributes file
      project.repository.copy_gitattributes(params[:ref]) if default_branch?
    end

    def branch_change_hooks
      enqueue_process_commit_messages
    end

    def branch_remove_hooks
      project.repository.after_remove_branch(expire_cache: false)
    end

    # Schedules processing of commit messages
    def enqueue_process_commit_messages
      referencing_commits = limited_commits.select(&:matches_cross_reference_regex?)

      upstream_commit_ids = upstream_commit_ids(referencing_commits)

      referencing_commits.each do |commit|
        # Avoid reprocessing commits that already exist upstream if the project
        # is a fork. This will prevent duplicated/superfluous system notes on
        # mentionables referenced by a commit that is pushed to the upstream,
        # that is then also pushed to forks when these get synced by users.
        next if upstream_commit_ids.include?(commit.id)

        ProcessCommitWorker.perform_async(
          project.id,
          current_user.id,
          commit.to_hash,
          default_branch?
        )
      end
    end

    def enqueue_update_gpg_signatures
      unsigned = GpgSignature.unsigned_commit_shas(limited_commits.map(&:sha))
      return if unsigned.empty?

      signable = Gitlab::Git::Commit.shas_with_signatures(project.repository, unsigned)
      return if signable.empty?

      CreateGpgSignatureWorker.perform_async(signable, project.id)
    end

    # It's not sufficient to just check for a blank SHA as it's possible for the
    # branch to be pushed, but for the `post-receive` hook to never run:
    # https://gitlab.com/gitlab-org/gitlab-ce/issues/59257
    def creating_branch?
      strong_memoize(:creating_branch) do
        Gitlab::Git.blank_ref?(params[:oldrev]) ||
          !project.repository.branch_exists?(branch_name)
      end
    end

    def updating_branch?
      !creating_branch? && !removing_branch?
    end

    def removing_branch?
      Gitlab::Git.blank_ref?(params[:newrev])
    end

    def creating_default_branch?
      creating_branch? && default_branch?
    end

    def count_commits_in_branch
      strong_memoize(:count_commits_in_branch) do
        project.repository.commit_count_for_ref(params[:ref])
      end
    end

    def default_branch?
      strong_memoize(:default_branch) do
        [nil, branch_name].include?(project.default_branch)
      end
    end

    def branch_name
      strong_memoize(:branch_name) { Gitlab::Git.ref_name(params[:ref]) }
    end

    def upstream_commit_ids(commits)
      set = Set.new

      upstream_project = project.fork_source
      if upstream_project
        upstream_project
          .commits_by(oids: commits.map(&:id))
          .each { |commit| set << commit.id }
      end

      set
    end
  end
end
