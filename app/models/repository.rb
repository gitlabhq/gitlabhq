class Repository
  include Gitlab::ShellAdapter

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

  def find_branch(name)
    branches.find { |branch| branch.name == name }
  end

  def find_tag(name)
    tags.find { |tag| tag.name == name }
  end

  def add_branch(branch_name, ref)
    Rails.cache.delete(cache_key(:branch_names))

    gitlab_shell.add_branch(path_with_namespace, branch_name, ref)
  end

  def add_tag(tag_name, ref)
    Rails.cache.delete(cache_key(:tag_names))

    gitlab_shell.add_tag(path_with_namespace, tag_name, ref)
  end

  def rm_branch(branch_name)
    Rails.cache.delete(cache_key(:branch_names))

    gitlab_shell.rm_branch(path_with_namespace, branch_name)
  end

  def rm_tag(tag_name)
    Rails.cache.delete(cache_key(:tag_names))

    gitlab_shell.rm_tag(path_with_namespace, tag_name)
  end

  def round_commit_count
    if commit_count > 10000
      '10000+'
    elsif commit_count > 5000
      '5000+'
    elsif commit_count > 1000
      '1000+'
    else
      commit_count
    end
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

  def commit_count
    Rails.cache.fetch(cache_key(:commit_count)) do
      raw_repository.raw.commit_count
    end
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
    Rails.cache.delete(cache_key(:commit_count))
    Rails.cache.delete(cache_key(:graph_log))
  end

  def graph_log
    Rails.cache.fetch(cache_key(:graph_log)) do
      stats = Gitlab::Git::GitStats.new(raw, root_ref)
      stats.parsed_log
    end
  end

  def cache_key(type)
    "#{type}:#{path_with_namespace}"
  end

  def method_missing(m, *args, &block)
    raw_repository.send(m, *args, &block)
  end

  def respond_to?(method)
    return true if raw_repository.respond_to?(method)

    super
  end
end
