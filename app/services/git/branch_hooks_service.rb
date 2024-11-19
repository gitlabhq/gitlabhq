# frozen_string_literal: true

module Git
  class BranchHooksService < ::Git::BaseHooksService
    include Gitlab::InternalEventsTracking
    extend ::Gitlab::Utils::Override

    JIRA_SYNC_BATCH_SIZE = 20
    JIRA_SYNC_BATCH_DELAY = 10.seconds

    def execute
      execute_branch_hooks

      super.tap do
        enqueue_update_signatures
      end
    end

    private

    alias_method :removing_branch?, :removing_ref?

    def hook_name
      :push_hooks
    end

    def limited_commits
      strong_memoize(:limited_commits) { threshold_commits.last(PROCESS_COMMIT_LIMIT) }
    end

    # Taking limit+1 commits allows us to detect when the limit is in effect
    def threshold_commits
      strong_memoize(:threshold_commits) do
        if creating_default_branch?
          # The most recent PROCESS_COMMIT_LIMIT commits in the default branch.
          # They are returned newest-to-oldest, but we need to present them oldest-to-newest
          project.repository.commits(newrev, limit: PROCESS_COMMIT_LIMIT + 1).reverse!
        elsif creating_branch?
          # Use the pushed commits that aren't reachable by the default branch
          # as a heuristic. This may include more commits than are actually
          # pushed, but that shouldn't matter because we check for existing
          # cross-references later.
          project.repository.commits_between(project.default_branch, newrev, limit: PROCESS_COMMIT_LIMIT + 1)
        elsif updating_branch?
          project.repository.commits_between(oldrev, newrev, limit: PROCESS_COMMIT_LIMIT + 1)
        else # removing branch
          []
        end
      end
    end

    def commits_count
      strong_memoize(:commits_count) do
        next threshold_commits.count if
          strong_memoized?(:threshold_commits) &&
            threshold_commits.count <= PROCESS_COMMIT_LIMIT

        if creating_default_branch?
          project.repository.commit_count_for_ref(ref)
        elsif creating_branch?
          project.repository.count_commits_between(project.default_branch, newrev)
        elsif updating_branch?
          project.repository.count_commits_between(oldrev, newrev)
        else # removing branch
          0
        end
      end
    end

    override :invalidated_file_types
    def invalidated_file_types
      return super unless default_branch? && !creating_branch?

      modified_file_types
    end

    def modified_file_types
      paths = commit_paths.values.reduce(&:merge) || Set.new

      Gitlab::FileDetector.types_in_paths(paths)
    end

    def execute_branch_hooks
      project.repository.after_push_commit(branch_name)

      branch_create_hooks if creating_branch?
      branch_change_hooks if creating_branch? || updating_branch?
      branch_remove_hooks if removing_branch?

      track_process_commit_limit_overflow
    end

    def branch_create_hooks
      project.repository.after_create_branch(expire_cache: false)
      project.after_create_default_branch if default_branch?
    end

    def branch_change_hooks
      enqueue_process_commit_messages
      enqueue_jira_connect_sync_messages
      track_ci_config_change_event
    end

    def branch_remove_hooks
      enqueue_jira_connect_remove_branches
      project.repository.after_remove_branch(expire_cache: false)
    end

    def track_ci_config_change_event
      return unless default_branch?

      commits_changing_ci_config.each do |commit|
        track_internal_event('commit_change_to_ciconfigfile', user: commit.author, project: commit.project)
      end
    end

    def track_process_commit_limit_overflow
      return if threshold_commits.count <= PROCESS_COMMIT_LIMIT

      Gitlab::Metrics.add_event(:process_commit_limit_overflow)
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

        ProcessCommitWorker.perform_in(
          process_commit_worker_delay,
          project.id,
          current_user.id,
          commit.to_hash,
          default_branch?
        )
      end
    end

    def enqueue_jira_connect_sync_messages
      return unless project.jira_subscription_exists?

      branch_to_sync = branch_name if Atlassian::JiraIssueKeyExtractors::Branch.has_keys?(project, branch_name)
      commits_to_sync = filtered_commit_shas

      return if branch_to_sync.nil? && commits_to_sync.empty?

      if commits_to_sync.any?
        commits_to_sync.each_slice(JIRA_SYNC_BATCH_SIZE).with_index do |commits, i|
          JiraConnect::SyncBranchWorker.perform_in(
            JIRA_SYNC_BATCH_DELAY * i,
            project.id,
            branch_to_sync,
            commits,
            Atlassian::JiraConnect::Client.generate_update_sequence_id
          )
        end
      else
        JiraConnect::SyncBranchWorker.perform_async(
          project.id,
          branch_to_sync,
          commits_to_sync,
          Atlassian::JiraConnect::Client.generate_update_sequence_id
        )
      end
    end

    def enqueue_jira_connect_remove_branches
      return unless project.jira_subscription_exists?

      return unless Atlassian::JiraIssueKeyExtractors::Branch.has_keys?(project, branch_name)

      Integrations::JiraConnect::RemoveBranchWorker.perform_async(
        project.id,
        {
          branch_name: branch_name
        }
      )
    end

    def filtered_commit_shas
      limited_commits.select { |commit| Atlassian::JiraIssueKeyExtractor.has_keys?(commit.safe_message) }.map(&:sha)
    end

    def signature_types
      [
        ::CommitSignatures::GpgSignature,
        ::CommitSignatures::X509CommitSignature,
        ::CommitSignatures::SshSignature
      ]
    end

    def unsigned_commit_shas(commits)
      commit_shas = commits.map(&:sha)

      signature_types
        .map { |signature| signature.unsigned_commit_shas(commit_shas) }
        .reduce(&:&)
    end

    def enqueue_update_signatures
      unsigned = unsigned_commit_shas(limited_commits)
      return if unsigned.empty?

      signable = Gitlab::Git::Commit.shas_with_signatures(project.repository, unsigned)
      return if signable.empty?

      CreateCommitSignatureWorker.perform_async(signable, project.id)
    end

    # It's not sufficient to just check for a blank SHA as it's possible for the
    # branch to be pushed, but for the `post-receive` hook to never run:
    # https://gitlab.com/gitlab-org/gitlab-foss/issues/59257
    def creating_branch?
      strong_memoize(:creating_branch) do
        Gitlab::Git.blank_ref?(oldrev) ||
          !project.repository.branch_exists?(branch_name)
      end
    end

    def updating_branch?
      !creating_branch? && !removing_branch?
    end

    def creating_default_branch?
      creating_branch? && default_branch?
    end

    def default_branch?
      strong_memoize(:default_branch) do
        [nil, branch_name].include?(project.default_branch)
      end
    end

    def branch_name
      strong_memoize(:branch_name) { Gitlab::Git.ref_name(ref) }
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

    def commits_changing_ci_config
      commit_paths.select do |commit, paths|
        next if commit.merge_commit?

        paths.include?(project.ci_config_path_or_default)
      end.keys
    end

    def commit_paths
      strong_memoize(:commit_paths) do
        limited_commits.to_h do |commit|
          paths = Set.new(commit.raw_deltas.map(&:new_path))
          [commit, paths]
        end
      end
    end

    def process_commit_worker_delay
      params[:process_commit_worker_pool]&.get_and_increment_delay || 0
    end
  end
end

Git::BranchHooksService.prepend_mod_with('Git::BranchHooksService')
