# frozen_string_literal: true

# A collection of Commit instances for a specific project and Git reference.
class CommitCollection
  include Enumerable
  include Gitlab::Utils::StrongMemoize

  attr_reader :project, :ref, :commits

  # project - The project the commits belong to.
  # commits - The Commit instances to store.
  # ref - The name of the ref (e.g. "master").
  def initialize(project, commits, ref = nil)
    @project = project
    @commits = commits
    @ref = ref
  end

  def each(&block)
    commits.each(&block)
  end

  def committers
    emails = without_merge_commits.map(&:committer_email).uniq

    User.by_any_email(emails)
  end

  def without_merge_commits
    strong_memoize(:without_merge_commits) do
      commits.reject(&:merge_commit?)
    end
  end

  # Sets the pipeline status for every commit.
  #
  # Setting this status ahead of time removes the need for running a query for
  # every commit we're displaying.
  def with_pipeline_status
    statuses = project.ci_pipelines.latest_status_per_commit(map(&:id), ref)

    each do |commit|
      commit.set_status_for_ref(ref, statuses[commit.id])
    end

    self
  end

  def respond_to_missing?(message, inc_private = false)
    commits.respond_to?(message, inc_private)
  end

  # rubocop:disable GitlabSecurity/PublicSend
  def method_missing(message, *args, &block)
    commits.public_send(message, *args, &block)
  end
end
