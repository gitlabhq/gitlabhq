# frozen_string_literal: true

# Worker for processing individual commit messages pushed to a repository.
#
# Jobs for this worker are scheduled for every commit that contains mentionable
# references in its message and does not exist in the upstream project. As a
# result of this the workload of this worker should be kept to a bare minimum.
# Consider using an extra worker if you need to add any extra (and potentially
# slow) processing of commits.
class ProcessCommitWorker
  include ApplicationWorker

  MAX_TIME_TRACKING_REFERENCES = 5
  DEFER_ON_HEALTH_DELAY = 5.seconds

  data_consistency :sticky

  sidekiq_options retry: 3

  feature_category :source_code_management
  urgency :high
  weight 3
  idempotent!
  loggable_arguments 2, 3
  deduplicate :until_executed

  concurrency_limit -> { 1000 }

  defer_on_database_health_signal :gitlab_main, [:notes], DEFER_ON_HEALTH_DELAY

  def self.defer_on_database_health_signal?(job_args: [])
    return false if job_args.empty?

    Feature.enabled?(:process_commit_worker_deferred, Project.actor_from_id(job_args[0]))
  end

  # project_id - The ID of the project this commit belongs to.
  # user_id - The ID of the user that pushed the commit.
  # commit_hash - Hash containing commit details to use for constructing a
  #               Commit object without having to use the Git repository.
  # default - The data was pushed to the default branch.
  def perform(project_id, user_id, commit_hash, default = false)
    project = Project.id_in(project_id).first

    return unless project

    user = User.id_in(user_id).first

    return unless user

    commit = Commit.build_from_sidekiq_hash(project, commit_hash)

    process_commit_message(project, commit, user, default)
    update_issue_metrics(commit, user)
  end

  private

  def process_commit_message(project, commit, user, default = false)
    # Ignore closing references from GitLab-generated commit messages.
    find_closing_issues = default && !commit.merged_merge_request?(user)
    closed_issues = find_closing_issues ? issues_to_close(project, commit, user) : []

    close_issues(project, user, commit, closed_issues) if closed_issues.any?
    commit.create_cross_references!(user, closed_issues)

    return unless Feature.enabled?(:commit_time_tracking, project)

    track_time_from_commit_message(project, commit, user)
  end

  def track_time_from_commit_message(project, commit, user)
    # Pre-validate commit message to prevent abuse
    validated_message = validate_and_limit_time_tracking_references(commit.safe_message, commit, project, user)
    return unless validated_message

    time_tracking_extractor = Gitlab::WorkItems::TimeTrackingExtractor.new(project, user)
    time_spent_entries = time_tracking_extractor.extract_time_spent(validated_message)

    time_spent_entries.each do |issue, time_spent|
      next if project.forked_from?(issue.project)
      next unless issue.supports_time_tracking?
      # Only log time if the user has permission to do so
      next unless Ability.allowed?(user, :create_timelog, issue)

      # Add commit information to the time tracking description
      description = "#{commit.title} (Commit #{commit.short_id})"

      # Check if a time entry with this commit info already exists
      # This prevents duplicate time tracking when commits appear multiple times in history
      duplicate_finder = Timelogs::TimelogsFinder.new(issue, summary: description)
      next if duplicate_finder.execute.exists?

      result = ::Timelogs::CreateService.new(
        issue,
        time_spent,
        commit.committed_date,
        description,
        user
      ).execute

      next if result.success?

      log_hash_metadata_on_done(
        issue_id: issue.id,
        project_id: project.id,
        commit_id: commit.id
      )

      Gitlab::AppLogger.error(
        message: "Failed to create timelog from commit",
        issue_id: issue.id,
        project_id: project.id,
        commit_id: commit.id,
        error_message: result.message
      )
    end
  end

  def close_issues(project, user, commit, issues)
    Issues::CloseWorker.bulk_perform_async_with_contexts(
      issues,
      arguments_proc: ->(issue) {
        [
          project.id,
          issue.id,
          issue.class.to_s,
          { user_id: user.id, commit_hash: commit.to_hash }
        ]
      },
      context_proc: ->(issue) { { project: project } }
    )
  end

  def issues_to_close(project, commit, user)
    Gitlab::ClosingIssueExtractor
      .new(project, user)
      .closed_by_message(commit.safe_message)
      .reject { |issue| issue.is_a?(Issue) && !issue.autoclose_by_merged_closing_merge_request? }
  end

  def update_issue_metrics(commit, user)
    mentioned_issues = commit.all_references(user).issues

    return if mentioned_issues.empty?

    Issue::Metrics.for_issues(mentioned_issues)
      .with_first_mention_not_earlier_than(commit.committed_date)
      .update_all(first_mentioned_in_commit_at: commit.committed_date)
  end

  def validate_and_limit_time_tracking_references(message, commit, project, user)
    return if message.blank?

    # Check if message contains time tracking syntax
    return unless message.match?(Gitlab::WorkItems::TimeTrackingExtractor.reference_pattern)

    issue_references = message.scan(Issue.reference_pattern)

    if issue_references.count > MAX_TIME_TRACKING_REFERENCES
      # Log the abuse attempt
      Gitlab::AppLogger.warn(
        message: "Time tracking abuse prevented: too many issue references",
        issue_count: issue_references.count,
        commit_id: commit.id,
        project_id: project.id,
        author_id: commit.author&.id,
        user_id: user.id
      )

      return
    end

    message
  end
end
