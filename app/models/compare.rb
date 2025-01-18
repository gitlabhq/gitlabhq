# frozen_string_literal: true

class Compare
  include Gitlab::Utils::StrongMemoize
  include ActsAsPaginatedDiff
  include ::Repositories::StreamableDiff

  delegate :same, :head, :base, :generated_files, to: :@compare

  attr_reader :project

  def self.decorate(compare, project)
    if compare.is_a?(Compare)
      compare
    else
      self.new(compare, project)
    end
  end

  def initialize(compare, project, base_sha: nil, straight: false)
    @compare = compare
    @project = project
    @base_sha = base_sha
    @straight = straight
  end

  # Return a Hash of parameters for passing to a URL helper
  #
  # See `namespace_project_compare_url`
  def to_param
    {
      from: @straight ? start_commit_sha : (base_commit_sha || start_commit_sha),
      to: head_commit_sha
    }
  end

  def cache_key
    [@project, :compare, diff_refs.hash]
  end

  def commits
    @commits ||= begin
      decorated_commits = Commit.decorate(@compare.commits, project)
      CommitCollection.new(project, decorated_commits)
    end
  end

  def start_commit
    strong_memoize(:start_commit) do
      commit = @compare.base

      ::Commit.new(commit, project) if commit
    end
  end

  def head_commit
    strong_memoize(:head_commit) do
      commit = @compare.head

      ::Commit.new(commit, project) if commit
    end
  end
  alias_method :commit, :head_commit

  def start_commit_sha
    start_commit&.sha
  end

  def base_commit_sha
    strong_memoize(:base_commit) do
      next unless start_commit && head_commit

      @base_sha || project.merge_base_commit(start_commit.id, head_commit.id)&.sha
    end
  end

  def head_commit_sha
    commit&.sha
  end

  def raw_diffs(...)
    @compare.diffs(...)
  end

  def diffs(diff_options = nil)
    Gitlab::Diff::FileCollection::Compare.new(self,
      project: project,
      diff_options: diff_options,
      diff_refs: diff_refs)
  end

  def repository
    project.repository
  end

  def diff_refs
    Gitlab::Diff::DiffRefs.new(
      base_sha: @straight ? start_commit_sha : base_commit_sha,
      start_sha: start_commit_sha,
      head_sha: head_commit_sha
    )
  end

  def changed_paths
    project
      .repository
      .find_changed_paths(
        [Gitlab::Git::DiffTree.new(diff_refs.base_sha, diff_refs.head_sha)],
        find_renames: true
      )
  end

  def modified_paths
    paths = Set.new
    diffs.diff_files.each do |diff|
      paths.add diff.old_path
      paths.add diff.new_path
    end
    paths.to_a
  end
end
