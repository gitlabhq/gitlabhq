# frozen_string_literal: true

# A collection of Commit instances for a specific container and Git reference.
class CommitCollection
  include Enumerable
  include Gitlab::Utils::StrongMemoize

  attr_reader :container, :ref, :commits

  delegate :repository, to: :container, allow_nil: true
  delegate :project, to: :repository, allow_nil: true

  # container - The object the commits belong to.
  # commits - The Commit instances to store.
  # ref - The name of the ref (e.g. "master").
  def initialize(container, commits, ref = nil)
    @container = container
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

  # Returns the collection with the latest pipeline for every commit pre-set.
  #
  # Setting the pipeline for each commit ahead of time removes the need for running
  # a query for every commit we're displaying.
  def with_latest_pipeline(ref = nil)
    return self unless project

    pipelines = project.ci_pipelines.latest_pipeline_per_commit(map(&:id), ref)

    each do |commit|
      commit.set_latest_pipeline_for_ref(ref, pipelines[commit.id])
    end

    self
  end

  # Returns the collection with markdown fields preloaded.
  #
  # Get the markdown cache from redis using pipeline to prevent n+1 requests
  # when rendering the markdown of an attribute (e.g. title, full_title,
  # description).
  def with_markdown_cache
    Commit.preload_markdown_cache!(commits)

    self
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
    # A container is needed in order to fetch data from gitaly. Containers
    # can be absent from commits in certain rare situations (like when
    # viewing a MR of a deleted fork). In these cases, assume that the
    # enriched data is not needed.
    return self if container.blank? || fully_enriched?

    # Batch load full Commits from the repository
    # and map to a Hash of id => Commit
    replacements = Hash[unenriched.map do |c|
      [c.id, Commit.lazy(container, c.id)]
    end.compact]

    # Replace the commits, keeping the same order
    @commits = @commits.map do |original_commit|
      # Return the original instance: if it didn't need to be batchloaded, it was
      # already enriched.
      batch_loaded_commit = replacements.fetch(original_commit.id, original_commit)

      # If batch loading the commit failed, fall back to the original commit.
      # We need to explicitly check `.nil?` since otherwise a `BatchLoader` instance
      # that looks like `nil` is returned.
      batch_loaded_commit.nil? ? original_commit : batch_loaded_commit
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
