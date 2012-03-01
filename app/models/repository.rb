require File.join(Rails.root, "lib", "gitlabhq", "git_host")

class Repository
  attr_accessor :project

  def self.default_ref
    "master"
  end

  def self.access_options
    {}
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

  def write_hooks
    %w(post-receive).each do |hook|
      write_hook(hook, File.read(File.join(Rails.root, 'lib', "#{hook}-hook")))
    end
  end

  def write_hook(name, content)
    hook_file = File.join(project.path_to_repo, 'hooks', name)

    File.open(hook_file, 'w') do |f|
      f.write(content)
    end

    File.chmod(0775, hook_file)
  end

  def repo
    @repo ||= Grit::Repo.new(project.path_to_repo)
  end

  def url_to_repo
    Gitlabhq::GitHost.url_to_repo(path)
  end

  def path_to_repo
    File.join(GIT_HOST["base_path"], "#{path}.git")
  end

  def update_repository
    Gitlabhq::GitHost.system.new.configure do |c|
      c.update_project(path, project)
    end

    write_hooks if File.exists?(project.path_to_repo)
  end

  def destroy_repository
    Gitlabhq::GitHost.system.new.configure do |c|
      c.destroy_project(@project)
    end
  end

  def repo_exists?
    @repo_exists ||= (repo && !repo.branches.empty?)
  rescue 
    @repo_exists = false
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

  def commits_with_refs(n = 20)
    commits = repo.branches.map { |ref| Commit.new(ref.commit, ref) }

    commits.sort! do |x, y|
      y.committed_date <=> x.committed_date
    end

    commits[0..n]
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

  def commits_between(from, to)
    repo.commits_between(from, to).map { |c| Commit.new(c) }
  end
end
