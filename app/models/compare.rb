class Compare
  delegate :same, :head, :base, to: :@compare

  def self.decorate(compare, project)
    if compare.is_a?(Compare)
      compare
    else
      self.new(compare, project)
    end
  end

  def initialize(compare, project)
    @compare = compare
    @project = project
  end

  def commits
    @commits ||= Commit.decorate(@compare.commits, @project)
  end

  def start_commit
    return @start_commit if defined?(@start_commit)

    commit = @compare.base
    @start_commit = commit ? ::Commit.new(commit, @project) : nil
  end

  def commit
    return @commit if defined?(@commit)

    commit = @compare.head
    @commit = commit ? ::Commit.new(commit, @project) : nil
  end
  alias_method :head_commit, :commit

  # Used only on emails_on_push_worker.rb
  def base_commit=(commit)
    @base_commit = commit
  end

  def base_commit
    return @base_commit if defined?(@base_commit)

    @base_commit = if start_commit && commit
                     @project.merge_base_commit(start_commit.id, commit.id)
                   else
                     nil
                   end
  end

  # keyword args until we get ride of diff_refs as argument
  def diff_file_collection(diff_options:, diff_refs: self.diff_refs)
    Gitlab::Diff::FileCollection::Compare.new(@compare,
      project: @project,
      diff_options: diff_options,
      diff_refs: diff_refs)
  end

  def diff_refs
    @diff_refs ||= Gitlab::Diff::DiffRefs.new(
      base_sha:  base_commit.try(:sha),
      start_sha: start_commit.try(:sha),
      head_sha: commit.try(:sha)
    )
  end
end
