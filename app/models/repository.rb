class Repository
  include Gitlab::ShellAdapter

  attr_accessor :raw_repository, :path_with_namespace

  def initialize(path_with_namespace, default_branch = nil)
    @path_with_namespace = path_with_namespace
    @raw_repository = Gitlab::Git::Repository.new(path_to_repo) if path_with_namespace
  rescue Gitlab::Git::Repository::NoRepository
    nil
  end

  # Return absolute path to repository
  def path_to_repo
    @path_to_repo ||= File.expand_path(
      File.join(Gitlab.config.gitlab_shell.repos_path, path_with_namespace + ".git")
    )
  end

  def exists?
    raw_repository
  end

  def empty?
    raw_repository.empty?
  end

  def commit(id = 'HEAD')
    return nil unless raw_repository
    commit = Gitlab::Git::Commit.find(raw_repository, id)
    commit = Commit.new(commit) if commit
    commit
  rescue Rugged::OdbError
    nil
  end

  def commits(ref, path = nil, limit = nil, offset = nil, skip_merges = false)
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

  def add_branch(branch_name, ref)
    cache.expire(:branch_names)
    @branches = nil

    gitlab_shell.add_branch(path_with_namespace, branch_name, ref)
  end

  def add_tag(tag_name, ref, message = nil)
    cache.expire(:tag_names)
    @tags = nil

    gitlab_shell.add_tag(path_with_namespace, tag_name, ref, message)
  end

  def rm_branch(branch_name)
    cache.expire(:branch_names)
    @branches = nil

    gitlab_shell.rm_branch(path_with_namespace, branch_name)
  end

  def rm_tag(tag_name)
    cache.expire(:tag_names)
    @tags = nil

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
    cache.fetch(:branch_names) { raw_repository.branch_names }
  end

  def tag_names
    cache.fetch(:tag_names) { raw_repository.tag_names }
  end

  def commit_count
    cache.fetch(:commit_count) do
      begin
        raw_repository.commit_count(self.root_ref)
      rescue
        0
      end
    end
  end

  # Return repo size in megabytes
  # Cached in redis
  def size
    cache.fetch(:size) { raw_repository.size }
  end

  def expire_cache
    %i(size branch_names tag_names commit_count graph_log
       readme version contribution_guide changelog license).each do |key|
      cache.expire(key)
    end
  end

  def graph_log
    cache.fetch(:graph_log) do
      commits = raw_repository.log(limit: 6000, skip_merges: true,
                                   ref: root_ref)

      commits.map do |rugged_commit|
        commit = Gitlab::Git::Commit.new(rugged_commit)

        {
          author_name: commit.author_name,
          author_email: commit.author_email,
          additions: commit.stats.additions,
          deletions: commit.stats.deletions,
        }
      end
    end
  end

  def lookup_cache
    @lookup_cache ||= {}
  end

  def method_missing(m, *args, &block)
    if m == :lookup && !block_given?
      lookup_cache[m] ||= {}
      lookup_cache[m][args.join(":")] ||= raw_repository.send(m, *args, &block)
    else
      raw_repository.send(m, *args, &block)
    end
  end

  def respond_to?(method)
    return true if raw_repository.respond_to?(method)

    super
  end

  def blob_at(sha, path)
    Gitlab::Git::Blob.find(self, sha, path)
  end

  def blob_by_oid(oid)
    Gitlab::Git::Blob.raw(self, oid)
  end

  def readme
    cache.fetch(:readme) { tree(:head).readme }
  end

  def version
    cache.fetch(:version) do
      tree(:head).blobs.find do |file|
        file.name.downcase == 'version'
      end
    end
  end

  def contribution_guide
    cache.fetch(:contribution_guide) do
      tree(:head).blobs.find do |file|
        file.contributing?
      end
    end
  end

  def changelog
    cache.fetch(:changelog) do
      tree(:head).blobs.find do |file|
        file.name =~ /^(changelog|history)/i
      end
    end
  end

  def license
    cache.fetch(:license) do
      tree(:head).blobs.find do |file|
        file.name =~ /^license/i
      end
    end
  end

  def head_commit
    @head_commit ||= commit(self.root_ref)
  end

  def head_tree
    @head_tree ||= Tree.new(self, head_commit.sha, nil)
  end

  def tree(sha = :head, path = nil)
    if sha == :head
      if path.nil?
        return head_tree
      else
        sha = head_commit.sha
      end
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
    args = %W(git rev-list --max-count=1 #{sha} -- #{path})
    sha = Gitlab::Popen.popen(args, path_to_repo).first.strip
    commit(sha)
  end

  # Remove archives older than 2 hours
  def clean_old_archives
    repository_downloads_path = Gitlab.config.gitlab.repository_downloads_path

    return unless File.directory?(repository_downloads_path)

    Gitlab::Popen.popen(%W(find #{repository_downloads_path} -not -path #{repository_downloads_path} -mmin +120 -delete))
  end

  def branches_sorted_by(value)
    case value
    when 'recently_updated'
      branches.sort do |a, b|
        commit(b.target).committed_date <=> commit(a.target).committed_date
      end
    when 'last_updated'
      branches.sort do |a, b|
        commit(a.target).committed_date <=> commit(b.target).committed_date
      end
    else
      branches
    end
  end

  def contributors
    commits = self.commits(nil, nil, 2000, 0, true)

    commits.group_by(&:author_email).map do |email, commits|
      contributor = Gitlab::Contributor.new
      contributor.email = email

      commits.each do |commit|
        if contributor.name.blank?
          contributor.name = commit.author_name
        end

        contributor.commits += 1
      end

      contributor
    end
  end

  def blob_for_diff(commit, diff)
    file = blob_at(commit.id, diff.new_path)

    unless file
      file = prev_blob_for_diff(commit, diff)
    end

    file
  end

  def prev_blob_for_diff(commit, diff)
    if commit.parent_id
      blob_at(commit.parent_id, diff.old_path)
    end
  end

  def branch_names_contains(sha)
    args = %W(git branch --contains #{sha})
    names = Gitlab::Popen.popen(args, path_to_repo).first

    if names.respond_to?(:split)
      names = names.split("\n").map(&:strip)

      names.each do |name|
        name.slice! '* '
      end

      names
    else
      []
    end
  end

  def tag_names_contains(sha)
    args = %W(git tag --contains #{sha})
    names = Gitlab::Popen.popen(args, path_to_repo).first

    if names.respond_to?(:split)
      names = names.split("\n").map(&:strip)

      names.each do |name|
        name.slice! '* '
      end

      names
    else
      []
    end
  end

  def branches
    @branches ||= raw_repository.branches
  end

  def tags
    @tags ||= raw_repository.tags
  end

  def root_ref
    @root_ref ||= raw_repository.root_ref
  end

  private

  def cache
    @cache ||= RepositoryCache.new(path_with_namespace)
  end
end
