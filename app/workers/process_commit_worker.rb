# Worker for processing individiual commit messages pushed to a repository.
#
# Jobs for this worker are scheduled for every commit that is being pushed. As a
# result of this the workload of this worker should be kept to a bare minimum.
# Consider using an extra worker if you need to add any extra (and potentially
# slow) processing of commits.
class ProcessCommitWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  # project_id - The ID of the project this commit belongs to.
  # user_id - The ID of the user that pushed the commit.
  # commit_sha - The SHA1 of the commit to process.
  # default - The data was pushed to the default branch.
  def perform(project_id, user_id, commit_sha, default = false)
    project = Project.find_by(id: project_id)

    return unless project

    user = User.find_by(id: user_id)

    return unless user

    commit = find_commit(project, commit_sha)

    return unless commit

    author = commit.author || user

    process_commit_message(project, commit, user, author, default)

    update_issue_metrics(commit, author)
  end

  def process_commit_message(project, commit, user, author, default = false)
    closed_issues = default ? commit.closes_issues(user) : []

    unless closed_issues.empty?
      close_issues(project, user, author, commit, closed_issues)
    end

    commit.create_cross_references!(author, closed_issues)
  end

  def close_issues(project, user, author, commit, issues)
    # We don't want to run permission related queries for every single issue,
    # therefor we use IssueCollection here and skip the authorization check in
    # Issues::CloseService#execute.
    IssueCollection.new(issues).updatable_by_user(user).each do |issue|
      Issues::CloseService.new(project, author).
        close_issue(issue, commit: commit)
    end
  end

  def update_issue_metrics(commit, author)
    mentioned_issues = commit.all_references(author).issues

    Issue::Metrics.where(issue_id: mentioned_issues.map(&:id), first_mentioned_in_commit_at: nil).
      update_all(first_mentioned_in_commit_at: commit.committed_date)
  end

  private

  def find_commit(project, sha)
    project.commit(sha)
  end
end
