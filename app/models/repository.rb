class Repository
  attr_accessor :project

  def self.default_ref
    "master"
  end

  def initialize(project)
    @project = project
  end

  def path 
    @path ||= project.path
  end

  def project_id
    project.id
  end

  def repo
    @repo ||= Grit::Repo.new(project.path_to_repo)
  end

  def url_to_repo
    if !GITOSIS["port"] or GITOSIS["port"] == 22
      "#{GITOSIS["git_user"]}@#{GITOSIS["host"]}:#{path}.git"
    else
      "ssh://#{GITOSIS["git_user"]}@#{GITOSIS["host"]}:#{GITOSIS["port"]}/#{path}.git"
    end
  end

  def path_to_repo
    GITOSIS["base_path"] + path + ".git"
  end

  def update_gitosis_project
    Gitosis.new.configure do |c|
      c.update_project(path, project.gitosis_writers)
    end
  end

  def destroy_gitosis_project
    Gitosis.new.configure do |c|
      c.destroy_project(@project)
    end
  end

  def repo_exists?
    repo rescue false
  end

  def tags
    repo.tags.map(&:name).sort.reverse
  end

  def heads
    @heads ||= repo.heads
  end

  def tree(fcommit, path = nil)
    fcommit = commit if fcommit == :head
    tree = fcommit.tree
    path ? (tree / path) : tree
  end

  def commit(commit_id = nil)
    if commit_id
      repo.commits(commit_id).first
    else
      repo.commits.first
    end
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
