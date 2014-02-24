class Repository
  include Gitlab::ShellAdapter

  attr_accessor :raw_repository, :path_with_namespace

  def initialize(path_with_namespace, default_branch = nil)
    @path_with_namespace = path_with_namespace
    @raw_repository = Gitlab::Git::Repository.new(path_to_repo) if path_with_namespace
  rescue Gitlab::Git::Repository::NoRepository
    nil
  end

  def path_to_repo
    @path_to_repo ||= File.join(Gitlab.config.gitlab_shell.repos_path, path_with_namespace + ".git")
  end

  def exists?
    raw_repository
  end

  def empty?
    raw_repository.empty?
  end

  def commit(id = nil)
    return nil unless raw_repository
    commit = Gitlab::Git::Commit.find(raw_repository, id)
    commit = Commit.new(commit) if commit
    commit
  end

  def commits(ref, path = nil, limit = nil, offset = nil)
    commits = Gitlab::Git::Commit.where(
      repo: raw_repository,
      ref: ref,
      path: path,
      limit: limit,
      offset: offset,
    )
    commits = Commit.decorate(commits) if commits.present?
    commits
  end

  def commits_between(from, to)
    commits = Gitlab::Git::Commit.between(raw_repository, from, to)
    commits = Commit.decorate(commits) if commits.present?
    commits
  end

  def find_branch(name)
    branches.find { |branch| branch.name == name }
  end

  def find_tag(name)
    tags.find { |tag| tag.name == name }
  end

  def recent_branches(limit = 20)
    branches.sort do |a, b|
      commit(b.target).committed_date <=> commit(a.target).committed_date
    end[0..limit]
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
      begin
        raw_repository.raw.commit_count
      rescue
        0
      end
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
    Rails.cache.delete(cache_key(:readme))
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

  def blob_at(sha, path)
    Gitlab::Git::Blob.find(self, sha, path)
  end

  def readme
    Rails.cache.fetch(cache_key(:readme)) do
      tree(:head).readme
    end
  end

  def head_commit
    commit(self.root_ref)
  end

  def tree(sha = :head, path = nil)
    if sha == :head
      sha = head_commit.sha
    end

    Tree.new(self, sha, path)
  end

  def blob_at_branch(branch_name, path)
    last_commit = commit(branch_name)

    if last_commit
      blob_at(last_commit.sha, path)
    else
      nil
    end
  end

  # Returns url for submodule
  #
  # Ex.
  #   @repository.submodule_url_for('master', 'rack')
  #   # => git@localhost:rack.git
  #
  def submodule_url_for(ref, path)
    if submodules(ref).any?
      submodule = submodules(ref)[path]

      if submodule
        submodule['url']
      end
    end
  end

  def last_commit_for_path(sha, path)
    commits(sha, path, 1).last
  end
end
