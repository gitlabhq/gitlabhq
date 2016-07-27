class Compare
  delegate :same, :head, :base, to: :@compare

  attr_reader :project

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
    @commits ||= Commit.decorate(@compare.commits, project)
  end

  def start_commit
    return @start_commit if defined?(@start_commit)

    commit = @compare.base
    @start_commit = commit ? ::Commit.new(commit, project) : nil
  end

  def head_commit
    return @head_commit if defined?(@head_commit)

    commit = @compare.head
    @head_commit = commit ? ::Commit.new(commit, project) : nil
  end
  alias_method :commit, :head_commit

  def base_commit
    return @base_commit if defined?(@base_commit)

    @base_commit = if start_commit && head_commit
                     project.merge_base_commit(start_commit.id, head_commit.id)
                   else
                     nil
                   end
  end

  def raw_diffs(*args)
    @compare.diffs(*args)
  end

  def diffs(diff_options:)
    Gitlab::Diff::FileCollection::Compare.new(self,
      project: project,
      diff_options: diff_options,
      diff_refs: diff_refs)
  end

  def diff_refs
    Gitlab::Diff::DiffRefs.new(
      base_sha:  base_commit.try(:sha),
      start_sha: start_commit.try(:sha),
      head_sha: commit.try(:sha)
    )
  end
end
