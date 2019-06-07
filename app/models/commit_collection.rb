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
      # `#enrich!` the collection to ensure all commits contain
      # the necessary parent data
      enrich!.commits.reject(&:merge_commit?)
    end
  end

  def unenriched
    commits.reject(&:gitaly_commit?)
  end

  def fully_enriched?
    unenriched.empty?
  end

  # Batch load any commits that are not backed by full gitaly data, and
  # replace them in the collection.
  def enrich!
    # A project is needed in order to fetch data from gitaly. Projects
    # can be absent from commits in certain rare situations (like when
    # viewing a MR of a deleted fork). In these cases, assume that the
    # enriched data is not needed.
    return self if project.blank? || fully_enriched?

    # Batch load full Commits from the repository
    # and map to a Hash of id => Commit
    replacements = Hash[unenriched.map do |c|
      [c.id, Commit.lazy(project, c.id)]
    end.compact]

    # Replace the commits, keeping the same order
    @commits = @commits.map do |c|
      replacements.fetch(c.id, c)
    end

    self
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
