require 'securerandom'

class Repository
  class PreReceiveError < StandardError; end
  class CommitError < StandardError; end

  include Gitlab::ShellAdapter

  attr_accessor :path_with_namespace, :project

  def self.clean_old_archives
    repository_downloads_path = Gitlab.config.gitlab.repository_downloads_path

    return unless File.directory?(repository_downloads_path)

    Gitlab::Popen.popen(%W(find #{repository_downloads_path} -not -path #{repository_downloads_path} -mmin +120 -delete))
  end

  def initialize(path_with_namespace, default_branch = nil, project = nil)
    @path_with_namespace = path_with_namespace
    @project = project
  end

  def raw_repository
    return nil unless path_with_namespace

    @raw_repository ||= begin
      repo = Gitlab::Git::Repository.new(path_to_repo)
      repo.autocrlf = :input
      repo
    rescue Gitlab::Git::Repository::NoRepository
      nil
    end
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

  #
  # Git repository can contains some hidden refs like:
  #   /refs/notes/*
  #   /refs/git-as-svn/*
  #   /refs/pulls/*
  # This refs by default not visible in project page and not cloned to client side.
  #
  # This method return true if repository contains some content visible in project page.
  #
  def has_visible_content?
    !raw_repository.branches.empty?
  end

  def commit(id = 'HEAD')
    return nil unless raw_repository
    commit = Gitlab::Git::Commit.find(raw_repository, id)
    commit = Commit.new(commit, @project) if commit
    commit
  rescue Rugged::OdbError
    nil
  end

  def commits(ref, path = nil, limit = nil, offset = nil, skip_merges = false)
    options = {
      repo: raw_repository,
      ref: ref,
      path: path,
      limit: limit,
      offset: offset,
      follow: path.present?
    }

    commits = Gitlab::Git::Commit.where(options)
    commits = Commit.decorate(commits, @project) if commits.present?
    commits
  end

  def commits_between(from, to)
    commits = Gitlab::Git::Commit.between(raw_repository, from, to)
    commits = Commit.decorate(commits, @project) if commits.present?
    commits
  end

  def find_commits_by_message(query)
    # Limited to 1000 commits for now, could be parameterized?
    args = %W(#{Gitlab.config.git.bin_path} log --pretty=%H --max-count 1000 --grep=#{query})

    git_log_results = Gitlab::Popen.popen(args, path_to_repo).first.lines.map(&:chomp)
    commits = git_log_results.map { |c| commit(c) }
    commits
  end

  def find_branch(name)
    branches.find { |branch| branch.name == name }
  end

  def find_tag(name)
    tags.find { |tag| tag.name == name }
  end

  def add_branch(branch_name, ref)
    expire_branches_cache

    gitlab_shell.add_branch(path_with_namespace, branch_name, ref)
  end

  def add_tag(tag_name, ref, message = nil)
    expire_tags_cache

    gitlab_shell.add_tag(path_with_namespace, tag_name, ref, message)
  end

  def rm_branch(branch_name)
    expire_branches_cache

    gitlab_shell.rm_branch(path_with_namespace, branch_name)
  end

  def rm_tag(tag_name)
    expire_tags_cache

    gitlab_shell.rm_tag(path_with_namespace, tag_name)
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

  def cache_keys
    %i(size branch_names tag_names commit_count
       readme version contribution_guide changelog license)
  end

  def build_cache
    cache_keys.each do |key|
      unless cache.exist?(key)
        send(key)
      end
    end
  end

  def expire_tags_cache
    cache.expire(:tag_names)
    @tags = nil
  end

  def expire_branches_cache
    cache.expire(:branch_names)
    @branches = nil
  end

  def expire_cache
    cache_keys.each do |key|
      cache.expire(key)
    end
  end

  def rebuild_cache
    cache_keys.each do |key|
      cache.expire(key)
      send(key)
    end
  end

  def lookup_cache
    @lookup_cache ||= {}
  end

  def expire_branch_names
    cache.expire(:branch_names)
  end

  def method_missing(m, *args, &block)
    if m == :lookup && !block_given?
      lookup_cache[m] ||= {}
      lookup_cache[m][args.join(":")] ||= raw_repository.send(m, *args, &block)
    else
      raw_repository.send(m, *args, &block)
    end
  end

  def respond_to_missing?(method, include_private = false)
    raw_repository.respond_to?(method, include_private) || super
  end

  def blob_at(sha, path)
    unless Gitlab::Git.blank_ref?(sha)
      Gitlab::Git::Blob.find(self, sha, path)
    end
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
        file.name =~ /\A(changelog|history)/i
      end
    end
  end

  def license
    cache.fetch(:license) do
      tree(:head).blobs.find do |file|
        file.name =~ /\Alicense/i
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
    args = %W(#{Gitlab.config.git.bin_path} rev-list --max-count=1 #{sha} -- #{path})
    sha = Gitlab::Popen.popen(args, path_to_repo).first.strip
    commit(sha)
  end

  # Remove archives older than 2 hours
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
    blob_at(commit.id, diff.file_path)
  end

  def prev_blob_for_diff(commit, diff)
    if commit.parent_id
      blob_at(commit.parent_id, diff.old_path)
    end
  end

  def refs_contains_sha(ref_type, sha)
    args = %W(#{Gitlab.config.git.bin_path} #{ref_type} --contains #{sha})
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

  def branch_names_contains(sha)
    refs_contains_sha('branch', sha)
  end

  def tag_names_contains(sha)
    refs_contains_sha('tag', sha)
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

  def commit_dir(user, path, message, branch)
    commit_with_hooks(user, branch) do |ref|
      committer = user_to_committer(user)
      options = {}
      options[:committer] = committer
      options[:author] = committer

      options[:commit] = {
        message: message,
        branch: ref,
      }

      raw_repository.mkdir(path, options)
    end
  end

  def commit_file(user, path, content, message, branch, update)
    commit_with_hooks(user, branch) do |ref|
      committer = user_to_committer(user)
      options = {}
      options[:committer] = committer
      options[:author] = committer
      options[:commit] = {
        message: message,
        branch: ref,
      }

      options[:file] = {
        content: content,
        path: path,
        update: update
      }

      Gitlab::Git::Blob.commit(raw_repository, options)
    end
  end

  def remove_file(user, path, message, branch)
    commit_with_hooks(user, branch) do |ref|
      committer = user_to_committer(user)
      options = {}
      options[:committer] = committer
      options[:author] = committer
      options[:commit] = {
        message: message,
        branch: ref
      }

      options[:file] = {
        path: path
      }

      Gitlab::Git::Blob.remove(raw_repository, options)
    end
  end

  def user_to_committer(user)
    {
      email: user.email,
      name: user.name,
      time: Time.now
    }
  end

  def can_be_merged?(source_sha, target_branch)
    our_commit = rugged.branches[target_branch].target
    their_commit = rugged.lookup(source_sha)

    if our_commit && their_commit
      !rugged.merge_commits(our_commit, their_commit).conflicts?
    else
      false
    end
  end

  def merge(user, source_sha, target_branch, options = {})
    our_commit = rugged.branches[target_branch].target
    their_commit = rugged.lookup(source_sha)

    raise "Invalid merge target" if our_commit.nil?
    raise "Invalid merge source" if their_commit.nil?

    merge_index = rugged.merge_commits(our_commit, their_commit)
    return false if merge_index.conflicts?

    commit_with_hooks(user, target_branch) do |ref|
      actual_options = options.merge(
        parents: [our_commit, their_commit],
        tree: merge_index.write_tree(rugged),
        update_ref: ref
      )

      Rugged::Commit.create(rugged, actual_options)
    end
  end

  def merged_to_root_ref?(branch_name)
    branch_commit = commit(branch_name)
    root_ref_commit = commit(root_ref)

    if branch_commit
      is_ancestor?(branch_commit.id, root_ref_commit.id)
    else
      nil
    end
  end

  def merge_base(first_commit_id, second_commit_id)
    rugged.merge_base(first_commit_id, second_commit_id)
  end

  def is_ancestor?(ancestor_id, descendant_id)
    merge_base(ancestor_id, descendant_id) == ancestor_id
  end


  def search_files(query, ref)
    offset = 2
    args = %W(#{Gitlab.config.git.bin_path} grep -i -n --before-context #{offset} --after-context #{offset} -e #{query} #{ref || root_ref})
    Gitlab::Popen.popen(args, path_to_repo).first.scrub.split(/^--$/)
  end

  def parse_search_result(result)
    ref = nil
    filename = nil
    startline = 0

    result.each_line.each_with_index do |line, index|
      if line =~ /^.*:.*:\d+:/
        ref, filename, startline = line.split(':')
        startline = startline.to_i - index
        break
      end
    end

    data = ""

    result.each_line do |line|
      data << line.sub(ref, '').sub(filename, '').sub(/^:-\d+-/, '').sub(/^::\d+:/, '')
    end

    OpenStruct.new(
      filename: filename,
      ref: ref,
      startline: startline,
      data: data
    )
  end

  def fetch_ref(source_path, source_ref, target_ref)
    args = %W(#{Gitlab.config.git.bin_path} fetch -f #{source_path} #{source_ref}:#{target_ref})
    Gitlab::Popen.popen(args, path_to_repo)
  end

  def commit_with_hooks(current_user, branch)
    oldrev = Gitlab::Git::BLANK_SHA
    ref = Gitlab::Git::BRANCH_REF_PREFIX + branch
    gl_id = Gitlab::ShellEnv.gl_id(current_user)
    was_empty = empty?

    # Create temporary ref
    random_string = SecureRandom.hex
    tmp_ref = "refs/tmp/#{random_string}/head"

    unless was_empty
      oldrev = find_branch(branch).target
      rugged.references.create(tmp_ref, oldrev)
    end

    # Make commit in tmp ref
    newrev = yield(tmp_ref)

    unless newrev
      raise CommitError.new('Failed to create commit')
    end

    # Run GitLab pre-receive hook
    pre_receive_hook = Gitlab::Git::Hook.new('pre-receive', path_to_repo)
    status = pre_receive_hook.trigger(gl_id, oldrev, newrev, ref)

    if status
      if was_empty
        # Create branch
        rugged.references.create(ref, newrev)
      else
        # Update head
        current_head = find_branch(branch).target

        # Make sure target branch was not changed during pre-receive hook
        if current_head == oldrev
          rugged.references.update(ref, newrev)
        else
          raise CommitError.new('Commit was rejected because branch received new push')
        end
      end

      # Run GitLab post receive hook
      post_receive_hook = Gitlab::Git::Hook.new('post-receive', path_to_repo)
      post_receive_hook.trigger(gl_id, oldrev, newrev, ref)
    else
      # Remove tmp ref and return error to user
      rugged.references.delete(tmp_ref)

      raise PreReceiveError.new('Commit was rejected by pre-receive hook')
    end
  end

  private

  def cache
    @cache ||= RepositoryCache.new(path_with_namespace)
  end
end
