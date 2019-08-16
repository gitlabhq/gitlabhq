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

  # project_id - The ID of the project this commit belongs to.
  # user_id - The ID of the user that pushed the commit.
  # commit_hash - Hash containing commit details to use for constructing a
  #               Commit object without having to use the Git repository.
  # default - The data was pushed to the default branch.
  # rubocop: disable CodeReuse/ActiveRecord
  def perform(project_id, user_id, commit_hash, default = false)
    project = Project.find_by(id: project_id)

    return unless project

    user = User.find_by(id: user_id)

    return unless user

    commit = build_commit(project, commit_hash)
    author = commit.author || user

    process_commit_message(project, commit, user, author, default)
    update_issue_metrics(commit, author)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def process_commit_message(project, commit, user, author, default = false)
    # Ignore closing references from GitLab-generated commit messages.
    find_closing_issues = default && !commit.merged_merge_request?(user)
    closed_issues = find_closing_issues ? commit.closes_issues(user) : []

    close_issues(project, user, author, commit, closed_issues) if closed_issues.any?
    commit.create_cross_references!(author, closed_issues)
  end

  def close_issues(project, user, author, commit, issues)
    # We don't want to run permission related queries for every single issue,
    # therefore we use IssueCollection here and skip the authorization check in
    # Issues::CloseService#execute.
    IssueCollection.new(issues).updatable_by_user(user).each do |issue|
      Issues::CloseService.new(project, author)
        .close_issue(issue, closed_via: commit)
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def update_issue_metrics(commit, author)
    mentioned_issues = commit.all_references(author).issues

    return if mentioned_issues.empty?

    Issue::Metrics.where(issue_id: mentioned_issues.map(&:id), first_mentioned_in_commit_at: nil)
      .update_all(first_mentioned_in_commit_at: commit.committed_date)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def build_commit(project, hash)
    date_suffix = '_date'

    # When processing Sidekiq payloads various timestamps are stored as Strings.
    # Commit in turn expects Time-like instances upon input, so we have to
    # manually parse these values.
    hash.each do |key, value|
      if key.to_s.end_with?(date_suffix) && value.is_a?(String)
        hash[key] = Time.parse(value)
      end
    end

    Commit.from_hash(hash, project)
  end
end
