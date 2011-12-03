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
    if !GIT_HOST["port"] or GIT_HOST["port"] == 22
      "#{GIT_HOST["git_user"]}@#{GIT_HOST["host"]}:#{path}.git"
    else
      "ssh://#{GIT_HOST["git_user"]}@#{GIT_HOST["host"]}:#{GIT_HOST["port"]}/#{path}.git"
    end
  end

  def path_to_repo
    GIT_HOST["base_path"] + path + ".git"
  end

  def update_gitosis_project
    GitProxy.system.new.configure do |c|
      c.update_project(path, project.gitosis_writers)
    end
  end

  def destroy_gitosis_project
    GitProxy.system.new.configure do |c|
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
    commit = if commit_id
               repo.commits(commit_id).first
             else
               repo.commits.first
             end
    Commit.new(commit) if commit
  end

  def fresh_commits(n = 10)
    commits = heads.map do |h|
      repo.commits(h.name, n).map { |c| Commit.new(c, h) }
    end.flatten.uniq { |c| c.id }

    commits.sort! do |x, y|
      y.committed_date <=> x.committed_date
    end

    commits[0...n]
  end

  def commits_since(date)
    commits = heads.map do |h|
      repo.log(h.name, nil, :since => date).each { |c| Commit.new(c, h) }
    end.flatten.uniq { |c| c.id }

    commits.sort! do |x, y|
      y.committed_date <=> x.committed_date
    end

    commits
  end

  def commits(ref, path = nil, limit = nil, offset = nil)
    if path
      repo.log(ref, path, :max_count => limit, :skip => offset)
    elsif limit && offset
      repo.commits(ref, limit, offset)
    else
      repo.commits(ref)
    end.map{ |c| Commit.new(c) } 
  end
end
