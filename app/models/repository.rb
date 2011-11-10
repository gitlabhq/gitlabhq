class Repository
  attr_accessor :project

  def self.default_ref
    "master"
  end

  def initialize(project)
    @project = project
  end

  def repo
    @repo ||= Grit::Repo.new(project.path_to_repo)
  end

  def tags
    repo.tags.map(&:name).sort.reverse
  end

  def repo_exists?
    repo rescue false
  end

  def commit(commit_id = nil)
    if commit_id
      repo.commits(commit_id).first
    else
      repo.commits.first
    end
  end

  def tree(fcommit, path = nil)
    fcommit = commit if fcommit == :head
    tree = fcommit.tree
    path ? (tree / path) : tree
  end

  def fresh_commits(n = 10)
    commits = heads.map do |h|
      repo.commits(h.name, n)
    end.flatten.uniq { |c| c.id }

    commits.sort! do |x, y|
      y.committed_date <=> x.committed_date
    end

    commits[0...n]
  end

  def heads
    @heads ||= repo.heads
  end

  def commits_since(date)
    commits = heads.map do |h|
      repo.log(h.name, nil, :since => date)
    end.flatten.uniq { |c| c.id }

    commits.sort! do |x, y|
      y.committed_date <=> x.committed_date
    end

    commits
  end
end
