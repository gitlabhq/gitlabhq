class Repository
  attr_accessor :raw_repository

  def initialize(path_with_namespace, default_branch)
    @raw_repository = Gitlab::Git::Repository.new(path_with_namespace, default_branch)
  end

  def commit(id = nil)
    commit = raw_repository.commit(id)
    commit = Commit.new(commit) if commit
    commit
  end

  def commits(ref, path = nil, limit = nil, offset = nil)
    commits = raw_repository.commits(ref, path, limit, offset)
    commits = Commit.decorate(commits) if commits.present?
    commits
  end

  def commits_between(target, source)
    commits = raw_repository.commits_between(target, source)
    commits = Commit.decorate(commits) if commits.present?
    commits
  end

  def method_missing(m, *args, &block)
    raw_repository.send(m, *args, &block)
  end

  def respond_to?(method)
    return true if raw_repository.respond_to?(method)

    super
  end
end
