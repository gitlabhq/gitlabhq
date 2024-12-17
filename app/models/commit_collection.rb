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
  def initialize(container, commits, ref = nil, page: nil, per_page: nil, count: nil)
    @container = container
    @commits = commits
    @ref = ref
    @pagination = Gitlab::PaginationDelegate.new(page: page, per_page: per_page, count: count)
  end

  def each(&block)
    commits.each(&block)
  end

  def committers(with_merge_commits: false, lazy: false, include_author_when_signed: false)
    if lazy
      return committers_lazy(
        with_merge_commits: with_merge_commits,
        include_author_when_signed: include_author_when_signed
      ).flatten
    end

    User.by_any_email(
      committers_emails(
        with_merge_commits: with_merge_commits,
        include_author_when_signed: include_author_when_signed
      )
    )
  end

  def committers_lazy(with_merge_commits: false, include_author_when_signed: false)
    emails = committers_emails(
      with_merge_commits: with_merge_commits,
      include_author_when_signed: include_author_when_signed
    )

    emails.map do |email|
      BatchLoader.for(email.downcase).batch(default_value: []) do |committer_emails, loader|
        User.by_any_email(committer_emails).each do |user|
          loader.call(user.email) { |memo| memo << user }
        end
      end
    end
  end
  alias_method :add_committers_to_batch_loader, :committers_lazy

  def committer_user_ids
    committers.pluck(:id)
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
      pipeline = pipelines[commit.id]
      pipeline&.number_of_warnings # preload number of warnings

      commit.set_latest_pipeline_for_ref(ref, pipeline)
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
    replacements = unenriched.each_with_object({}) do |c, result|
      result[c.id] = Commit.lazy(container, c.id)
    end.compact

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

  def next_page
    @pagination.next_page
  end

  def load_tags
    oids = commits.map(&:id)
    references = repository.list_refs([Gitlab::Git::TAG_REF_PREFIX], pointing_at_oids: oids, peel_tags: true)
    oid_to_references = references.group_by { |reference| reference.peeled_target.presence || reference.target }

    return self if oid_to_references.empty?

    commits.each do |commit|
      grouped_references = oid_to_references[commit.id]
      next unless grouped_references

      commit.referenced_by = grouped_references.map(&:name)
    end

    self
  end

  private

  def committers_emails(with_merge_commits: false, include_author_when_signed: false)
    return committer_emails_for(commits, include_author_when_signed: include_author_when_signed) if with_merge_commits

    committer_emails_for(without_merge_commits, include_author_when_signed: include_author_when_signed)
  end

  def committer_emails_for(commits, include_author_when_signed: false)
    if include_author_when_signed
      commits.each(&:signature) # preload signatures
    end

    commits.filter_map do |commit|
      if include_author_when_signed && commit.signature&.verified_system?
        commit.author_email
      else
        commit.committer_email
      end
    end.uniq
  end
end
