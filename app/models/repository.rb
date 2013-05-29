class Repository
  attr_accessor :raw_repository

  def initialize(path_with_namespace, default_branch)
    @raw_repository = Gitlab::Git::Repository.new(path_with_namespace, default_branch)
  rescue Gitlab::Git::Repository::NoRepository
    nil
  end

  def exists?
    raw_repository
  end

  def empty?
    raw_repository.empty?
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

  def branch_names
    Rails.cache.fetch(cache_key(:branch_names)) do
      raw_repository.branch_names
    end
  end

  def tag_names
    Rails.cache.fetch(cache_key(:tag_names)) do
      raw_repository.tag_names
    end
  end

  def method_missing(m, *args, &block)
    raw_repository.send(m, *args, &block)
  end

  # Return repo size in megabytes
  # Cached in redis
  def size
    Rails.cache.fetch(cache_key(:size)) do
      raw_repository.size
    end
  end

  def expire_cache
    Rails.cache.delete(cache_key(:size))
    Rails.cache.delete(cache_key(:branch_names))
    Rails.cache.delete(cache_key(:tag_names))
  end

  def cache_key(type)
    "#{type}:#{path_with_namespace}"
  end

  def respond_to?(method)
    return true if raw_repository.respond_to?(method)

    super
  end
end
