# frozen_string_literal: true

require 'securerandom'

# Explicitly require licensee/license file in order to use Licensee::InvalidLicense class defined in
# https://github.com/licensee/licensee/blob/v9.14.1/lib/licensee/license.rb#L6
# The problem is that nested classes are not automatically preloaded which may lead to
# uninitialized constant exception being raised: https://gitlab.com/gitlab-org/gitlab/-/issues/356658
require 'licensee/license'

class Repository
  REF_MERGE_REQUEST = 'merge-requests'
  REF_KEEP_AROUND = 'keep-around'
  REF_ENVIRONMENTS = 'environments'
  REF_PIPELINES = 'pipelines'
  REF_TMP = 'tmp'

  ARCHIVE_CACHE_TIME = 60 # Cache archives referred to by a (mutable) ref for 1 minute
  ARCHIVE_CACHE_TIME_IMMUTABLE = 3600 # Cache archives referred to by an immutable reference for 1 hour

  RESERVED_REFS_NAMES = %W[
    heads
    tags
    replace
    #{REF_MERGE_REQUEST}
    #{REF_ENVIRONMENTS}
    #{REF_KEEP_AROUND}
    #{REF_PIPELINES}
  ].freeze

  FORMAT_SHA1 = 'sha1'
  FORMAT_SHA256 = 'sha256'

  include Gitlab::RepositoryCacheAdapter

  attr_accessor :full_path, :shard, :disk_path, :container, :repo_type

  delegate :lfs_enabled?, to: :container

  delegate_missing_to :raw_repository

  CreateTreeError = Class.new(StandardError)
  AmbiguousRefError = Class.new(StandardError)

  # Methods that cache data from the Git repository.
  #
  # Each entry in this Array should have a corresponding method with the exact
  # same name. The cache key used by those methods must also match method's
  # name.
  #
  # For example, for entry `:commit_count` there's a method called `commit_count` which
  # stores its data in the `commit_count` cache key.
  CACHED_METHODS = %i[size recent_objects_size commit_count readme_path contribution_guide
    changelog license_blob license_gitaly gitignore
    branch_names tag_names branch_count
    tag_count avatar exists? root_ref merged_branch_names
    has_visible_content? issue_template_names_hash merge_request_template_names_hash
    xcode_project? has_ambiguous_refs?].freeze

  # Certain method caches should be refreshed when certain types of files are
  # changed. This Hash maps file types (as returned by Gitlab::FileDetector) to
  # the corresponding methods to call for refreshing caches.
  METHOD_CACHES_FOR_FILE_TYPES = {
    readme: %i[readme_path],
    changelog: :changelog,
    license: %i[license_blob license_gitaly],
    contributing: :contribution_guide,
    gitignore: :gitignore,
    avatar: :avatar,
    issue_template: :issue_template_names_hash,
    merge_request_template: :merge_request_template_names_hash,
    xcode_config: :xcode_project?
  }.freeze

  def initialize(full_path, container, shard:, disk_path: nil, repo_type: Gitlab::GlRepository::PROJECT)
    @full_path = full_path
    @shard = shard
    @disk_path = disk_path || full_path
    @container = container
    @commit_cache = {}
    @repo_type = repo_type
  end

  def ==(other)
    other.is_a?(self.class) && @disk_path == other.disk_path
  end

  alias_method :eql?, :==

  def hash
    [self.class, @disk_path].hash
  end

  def raw_repository
    return unless full_path

    @raw_repository ||= initialize_raw_repository
  end

  alias_method :raw, :raw_repository

  def flipper_id
    raw_repository.flipper_id
  end

  # Don't use this! It's going away. Use Gitaly to read or write from repos.
  def path_to_repo
    @path_to_repo ||=
      begin
        storage = Gitlab.config.repositories.storages[shard]

        File.expand_path(
          File.join(storage.legacy_disk_path, disk_path + '.git')
        )
      end
  end

  def inspect
    "#<#{self.class.name}:#{@disk_path}>"
  end

  def commit(ref = nil)
    return unless exists?
    return ref if ref.is_a?(::Commit)

    find_commit(ref || root_ref)
  end

  # Finding a commit by the passed SHA
  # Also takes care of caching, based on the SHA
  def commit_by(oid:)
    return @commit_cache[oid] if @commit_cache.key?(oid)

    @commit_cache[oid] = find_commit(oid)
  end

  def commits_by(oids:)
    return [] unless oids.present?

    commits = Gitlab::Git::Commit.batch_by_oid(raw_repository, oids)

    if commits.present?
      Commit.decorate(commits, container)
    else
      []
    end
  end

  def commits(ref = nil, opts = {})
    options = {
      repo: raw_repository,
      ref: ref,
      path: opts[:path],
      author: opts[:author],
      follow: Array(opts[:path]).length == 1 && Feature.disabled?(:remove_file_commit_history_following, type: :ops),
      limit: opts[:limit],
      offset: opts[:offset],
      skip_merges: !!opts[:skip_merges],
      after: opts[:after],
      before: opts[:before],
      all: !!opts[:all],
      first_parent: !!opts[:first_parent],
      order: opts[:order],
      literal_pathspec: opts.fetch(:literal_pathspec, true),
      trailers: opts[:trailers],
      include_referenced_by: opts[:include_referenced_by]
    }

    commits = Gitlab::Git::Commit.where(options)
    commits = Commit.decorate(commits, container) if commits.present?

    CommitCollection.new(container, commits, ref)
  end

  def commits_between(from, to, limit: nil)
    commits = Gitlab::Git::Commit.between(raw_repository, from, to, limit: limit)
    commits = Commit.decorate(commits, container) if commits.present?
    commits
  end

  # Returns a list of commits that are not present in any reference
  def new_commits(newrev)
    commits = raw.new_commits(newrev)

    ::Commit.decorate(commits, container)
  end

  # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/384
  def find_commits_by_message(query, ref = nil, path = nil, limit = 1000, offset = 0)
    unless exists? && has_visible_content? && query.present?
      return []
    end

    commits = raw_repository.find_commits_by_message(query.strip, ref, path, limit, offset).map do |c|
      commit(c)
    end
    CommitCollection.new(container, commits, ref)
  end

  def list_commits_by(query, ref, author: nil, before: nil, after: nil, limit: 1000)
    return [] unless exists?
    return [] unless has_visible_content?
    return [] unless ref.present?

    commits = raw_repository.list_commits_by(
      query, ref, author: author, before: before, after: after, limit: limit).map do |c|
      commit(c)
    end
    CommitCollection.new(container, commits, ref)
  end

  def find_branch(name)
    raw_repository.find_branch(name)
  end

  def find_tag(name)
    if @tags.blank?
      raw_repository.find_tag(name)
    else
      tags.find { |tag| tag.name == name }
    end
  end

  def ambiguous_ref?(ref)
    tag_exists?(ref) && branch_exists?(ref)
  end

  # It's possible for a tag name to be a prefix (including slash) of a branch
  # name, or vice versa. For instance, a tag named `foo` means we can't create a
  # tag `foo/bar`, but we _can_ create a branch `foo/bar`.
  #
  # If we know a repository has no refs of this type (which is the common case)
  # then separating refs from paths - as in ExtractsRef - can be faster.
  #
  # This method only checks one level deep, so only prefixes that contain no
  # slashes are considered. If a repository has a tag `foo/bar` and a branch
  # `foo/bar/baz`, it will return false.
  def has_ambiguous_refs?
    return false unless branch_names.present? && tag_names.present?

    with_slash, no_slash = (branch_names + tag_names).partition { |ref| ref.include?('/') }

    return false if with_slash.empty?

    prefixes = no_slash.map { |ref| Regexp.escape(ref) }.join('|')
    prefix_regex = %r{^(#{prefixes})/}

    with_slash.any? do |ref|
      prefix_regex.match?(ref)
    end
  end
  cache_method :has_ambiguous_refs?

  def expand_ref(ref)
    if tag_exists?(ref)
      Gitlab::Git::TAG_REF_PREFIX + ref
    elsif branch_exists?(ref)
      Gitlab::Git::BRANCH_REF_PREFIX + ref
    end
  end

  def add_branch(user, branch_name, ref, expire_cache: true)
    branch = raw_repository.add_branch(branch_name, user: user, target: ref)

    after_create_branch(expire_cache: expire_cache)

    branch
  rescue Gitlab::Git::Repository::InvalidRef
    false
  end

  def add_tag(user, tag_name, target, message = nil)
    raw_repository.add_tag(tag_name, user: user, target: target, message: message)
  rescue Gitlab::Git::Repository::InvalidRef
    false
  end

  def rm_branch(user, branch_name, target_sha: nil)
    before_remove_branch

    raw_repository.rm_branch(branch_name, user: user, target_sha: target_sha)

    after_remove_branch
    true
  end

  def rm_tag(user, tag_name)
    before_remove_tag

    raw_repository.rm_tag(tag_name, user: user)

    after_remove_tag
    true
  end

  def ref_names
    branch_names + tag_names
  end

  def branch_exists?(branch_name)
    return false unless raw_repository

    branch_names_include?(branch_name)
  end

  def tag_exists?(tag_name)
    return false unless raw_repository

    tag_names_include?(tag_name)
  end

  def ref_exists?(ref)
    !!raw_repository&.ref_exists?(ref)
  rescue ArgumentError
    false
  end

  def branch_or_tag?(ref)
    return false unless exists?

    ref = Gitlab::Git.ref_name(ref, types: 'heads|tags')

    branch_exists?(ref) || tag_exists?(ref)
  end

  def search_branch_names(pattern)
    redis_set_cache.search('branch_names', pattern) { branch_names }
  end

  def languages
    return [] if empty?

    raw_repository.languages(root_ref)
  end

  def keep_around(*shas, source:)
    Gitlab::Git::KeepAround.execute(self, shas, source: source)
  end

  def archive_metadata(ref, storage_path, format = "tar.gz", append_sha:, path: nil)
    raw_repository.archive_metadata(
      ref,
      storage_path,
      project&.path,
      format,
      append_sha: append_sha,
      path: path
    )
  end

  def cached_methods
    CACHED_METHODS
  end

  def expire_tags_cache
    expire_method_caches(%i[tag_names tag_count has_ambiguous_refs?])
    @tags = nil
    @tag_names_include = nil
  end

  def expire_branches_cache
    expire_method_caches(%i[branch_names merged_branch_names branch_count has_visible_content? has_ambiguous_refs?])
    expire_protected_branches_cache

    @local_branches = nil
    @branch_exists_memo = nil
    @branch_names_include = nil
  end

  def expire_protected_branches_cache
    ProtectedBranches::CacheService.new(project).refresh if project # rubocop:disable CodeReuse/ServiceClass
  end

  def expire_statistics_caches
    expire_method_caches(%i[size recent_objects_size commit_count])
  end

  def expire_all_method_caches
    expire_method_caches(CACHED_METHODS)
  end

  def expire_avatar_cache
    expire_method_caches(%i[avatar])
  end

  # Refreshes the method caches of this repository.
  #
  # types - An Array of file types (e.g. `:readme`) used to refresh extra
  #         caches.
  def refresh_method_caches(types)
    return if types.empty?

    to_refresh = []

    types.each do |type|
      methods = METHOD_CACHES_FOR_FILE_TYPES[type.to_sym]

      to_refresh.concat(Array(methods)) if methods
    end

    expire_method_caches(to_refresh)

    to_refresh.each { |method| send(method) } # rubocop:disable GitlabSecurity/PublicSend
  end

  def expire_branch_cache(branch_name = nil)
    # When we push to the root branch we have to flush the cache for all other
    # branches as their statistics are based on the commits relative to the
    # root branch.
    if !branch_name || branch_name == root_ref
      branches.each do |branch|
        cache.expire(:"diverging_commit_counts_#{branch.name}")
        cache.expire(:"commit_count_#{branch.name}")
      end
    # In case a commit is pushed to a non-root branch we only have to flush the
    # cache for said branch.
    else
      cache.expire(:"diverging_commit_counts_#{branch_name}")
      cache.expire(:"commit_count_#{branch_name}")
    end
  end

  def expire_root_ref_cache
    expire_method_caches(%i[root_ref])
  end

  # Expires the cache(s) used to determine if a repository is empty or not.
  def expire_emptiness_caches
    return unless empty?

    expire_method_caches(%i[has_visible_content?])
    raw_repository.expire_has_local_branches_cache
  end

  def expire_exists_cache
    expire_method_caches(%i[exists?])
  end

  # expire cache that doesn't depend on repository data (when expiring)
  def expire_content_cache
    expire_tags_cache
    expire_branches_cache
    expire_root_ref_cache
    expire_emptiness_caches
    expire_exists_cache
    expire_statistics_caches
  end

  def expire_status_cache
    expire_exists_cache
    expire_root_ref_cache
    expire_emptiness_caches
  end

  # Runs code after a repository has been created.
  def after_create
    expire_status_cache

    repository_event(:create_repository)
  end

  # Runs code just before a repository is deleted.
  def before_delete
    expire_exists_cache
    expire_all_method_caches
    expire_branch_cache if exists?
    expire_content_cache

    repository_event(:remove_repository)
  end

  # Runs code just before the HEAD of a repository is changed.
  def before_change_head
    # Cached divergent commit counts are based on repository head
    expire_branch_cache
    expire_root_ref_cache

    repository_event(:change_default_branch)
  end

  # Runs code before pushing (= creating or removing) a tag.
  #
  # Note that this doesn't expire the tags. You may need to call
  # expire_caches_for_tags or expire_tags_cache.
  def before_push_tag
    repository_event(:push_tag)
  end

  def expire_caches_for_tags
    expire_statistics_caches
    expire_emptiness_caches
    expire_tags_cache
  end

  # Runs code before removing a tag.
  def before_remove_tag
    expire_caches_for_tags

    repository_event(:remove_tag)
  end

  # Runs code after removing a tag.
  def after_remove_tag
    expire_caches_for_tags
  end

  # Runs code after the HEAD of a repository is changed.
  def after_change_head
    expire_all_method_caches
    container.after_repository_change_head
  end

  # Runs code after a new commit has been pushed.
  def after_push_commit(branch_name)
    expire_statistics_caches
    expire_branch_cache(branch_name)

    repository_event(:push_commit, branch: branch_name)
  end

  # Runs code after a new branch has been created.
  def after_create_branch(expire_cache: true)
    expire_branches_cache if expire_cache

    repository_event(:push_branch)
  end

  # Runs code before removing an existing branch.
  def before_remove_branch
    expire_branches_cache

    repository_event(:remove_branch)
  end

  # Runs code after an existing branch has been removed.
  def after_remove_branch(expire_cache: true)
    expire_branches_cache if expire_cache
  end

  def lookup(sha)
    strong_memoize("lookup_#{sha}") do
      raw_repository.lookup(sha)
    end
  end

  def blob_at(sha, path, limit: Gitlab::Git::Blob::MAX_DATA_DISPLAY_SIZE)
    Blob.decorate(raw_repository.blob_at(sha, path, limit: limit), container)
  rescue Gitlab::Git::Repository::NoRepository
    nil
  end

  # items is an Array like: [[oid, path], [oid1, path1]]
  def blobs_at(items, blob_size_limit: Gitlab::Git::Blob::MAX_DATA_DISPLAY_SIZE)
    return [] unless exists?

    raw_repository.batch_blobs(items, blob_size_limit: blob_size_limit).map do |blob|
      Blob.decorate(blob, container)
    end
  rescue Gitlab::Git::Repository::NoRepository
    []
  end

  def root_ref
    raw_repository&.root_ref
  end
  cache_method_asymmetrically :root_ref

  # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/314
  def exists?
    return false unless full_path

    raw_repository.exists?
  end
  cache_method_asymmetrically :exists?

  # We don't need to cache the output of this method because both exists? and
  # has_visible_content? are already memoized and cached. There's no guarantee
  # that the values are expired and loaded atomically.
  def empty?
    return true unless exists?

    !has_visible_content?
  end

  # The size of this repository in megabytes.
  def size
    exists? ? raw_repository.size : 0.0
  end
  cache_method :size, fallback: 0.0

  # The recent objects size of this repository in mebibytes.
  def recent_objects_size
    exists? ? raw_repository.recent_objects_size : 0.0
  end
  cache_method :recent_objects_size, fallback: 0.0

  def commit_count
    root_ref ? raw_repository.commit_count(root_ref) : 0
  end
  cache_method :commit_count, fallback: 0

  def commit_count_for_ref(ref)
    return 0 unless exists?

    cache.fetch(:"commit_count_#{ref}") { raw_repository.commit_count(ref) }
  end

  delegate :branch_names, to: :raw_repository
  cache_method_as_redis_set :branch_names, fallback: []

  delegate :tag_names, to: :raw_repository
  cache_method_as_redis_set :tag_names, fallback: []

  delegate :branch_count, :tag_count, :has_visible_content?, to: :raw_repository
  cache_method :branch_count, fallback: 0
  cache_method :tag_count, fallback: 0
  cache_method_asymmetrically :has_visible_content?

  def avatar
    # n+1: https://gitlab.com/gitlab-org/gitlab-foss/issues/38327
    Gitlab::GitalyClient.allow_n_plus_1_calls do
      if tree = file_on_head(:avatar)
        tree.path
      end
    end
  end
  cache_method :avatar

  # store issue_template_names as hash
  def issue_template_names_hash
    Gitlab::Template::IssueTemplate.repository_template_names(project)
  end
  cache_method :issue_template_names_hash, fallback: {}

  def merge_request_template_names_hash
    Gitlab::Template::MergeRequestTemplate.repository_template_names(project)
  end
  cache_method :merge_request_template_names_hash, fallback: {}

  def readme
    head_tree&.readme
  end

  def readme_path
    head_tree&.readme_path
  end
  cache_method :readme_path

  def contribution_guide
    file_on_head(:contributing)
  end
  cache_method :contribution_guide

  def changelog
    file_on_head(:changelog)
  end
  cache_method :changelog

  def license_blob
    file_on_head(:license)
  end
  cache_method :license_blob

  def license_key
    license&.key
  end

  def license
    license_gitaly
  end

  def license_gitaly
    return unless exists?

    raw_repository.license
  end
  cache_method :license_gitaly

  def gitignore
    file_on_head(:gitignore)
  end
  cache_method :gitignore

  def jenkinsfile?
    file_on_head(:jenkinsfile).present?
  end

  def xcode_project?
    file_on_head(:xcode_config, :tree).present?
  end
  cache_method :xcode_project?

  def head_commit
    @head_commit ||= commit(self.root_ref)
  end

  def head_tree(skip_flat_paths: true)
    return if empty? || root_ref.nil?

    @head_tree ||= Tree.new(self, root_ref, nil, skip_flat_paths: skip_flat_paths, ref_type: 'heads')
  end

  def tree(sha = :head, path = nil, recursive: false, skip_flat_paths: true, pagination_params: nil, ref_type: nil, rescue_not_found: true)
    if sha == :head
      return if empty? || root_ref.nil?

      if path.nil?
        return head_tree(skip_flat_paths: skip_flat_paths)
      else
        sha = head_commit.sha
        ref_type = nil
      end
    end

    Tree.new(self, sha, path, recursive: recursive, skip_flat_paths: skip_flat_paths, pagination_params: pagination_params, ref_type: ref_type, rescue_not_found: rescue_not_found)
  end

  def blob_at_branch(branch_name, path)
    last_commit = commit(branch_name)

    if last_commit
      blob_at(last_commit.sha, path)
    end
  end

  def list_last_commits_for_tree(sha, path, offset: 0, limit: 25, literal_pathspec: false)
    commits = raw_repository.list_last_commits_for_tree(sha, path, offset: offset, limit: limit, literal_pathspec: literal_pathspec)

    commits.each do |path, commit|
      commits[path] = ::Commit.new(commit, container)
    end
  end

  def last_commit_for_path(sha, path, literal_pathspec: false)
    commit = raw_repository.last_commit_for_path(sha, path, literal_pathspec: literal_pathspec)
    ::Commit.new(commit, container) if commit
  end

  def last_commit_id_for_path(sha, path, literal_pathspec: false)
    key = path.blank? ? "last_commit_id_for_path:#{sha}" : "last_commit_id_for_path:#{sha}:#{Digest::SHA1.hexdigest(path)}"

    cache.fetch(key) do
      last_commit_for_path(sha, path, literal_pathspec: literal_pathspec)&.id
    end
  end

  def next_branch(name, opts = {})
    branch_ids = self.branch_names.map do |n|
      next 1 if n == name

      result = n.match(/\A#{name}-([0-9]+)\z/)
      result[1].to_i if result
    end.compact

    highest_branch_id = branch_ids.max || 0

    return name if opts[:mild] && 0 == highest_branch_id

    "#{name}-#{highest_branch_id + 1}"
  end

  def branches_sorted_by(sort_by, pagination_params = nil)
    raw_repository.local_branches(sort_by: sort_by, pagination_params: pagination_params)
  end

  def tags_sorted_by(value, pagination_params = nil)
    raw_repository.tags(sort_by: value, pagination_params: pagination_params)
  end

  # Params:
  #
  # order_by: name|email|commits
  # sort: asc|desc default: 'asc'
  def contributors(ref: nil, order_by: nil, sort: 'asc')
    commits = self.commits(ref, limit: 2000, offset: 0, skip_merges: true)

    commits = commits.group_by(&:author_email).map do |email, commits|
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
    Commit.order_by(collection: commits, order_by: order_by, sort: sort)
  end

  def branch_names_contains(sha, limit: 0, exclude_refs: [])
    refs = raw_repository.branch_names_contains_sha(sha, limit: adjust_containing_limit(limit: limit, exclude_refs: exclude_refs))

    adjust_containing_refs(limit: limit, refs: refs - exclude_refs)
  end

  def tag_names_contains(sha, limit: 0, exclude_refs: [])
    refs = raw_repository.tag_names_contains_sha(sha, limit: adjust_containing_limit(limit: limit, exclude_refs: exclude_refs))

    adjust_containing_refs(limit: limit, refs: refs - exclude_refs)
  end

  def local_branches
    @local_branches ||= raw_repository.local_branches
  end

  alias_method :branches, :local_branches

  def tags
    @tags ||= raw_repository.tags
  end

  def create_dir(user, path, **options)
    options[:actions] = [{ action: :create_dir, file_path: path }]

    commit_files(user, **options)
  end

  def create_file_actions(path, content, execute_filemode: nil)
    actions = [{ action: :create, file_path: path, content: content }]
    actions << { action: :chmod, file_path: path, execute_filemode: execute_filemode } unless execute_filemode.nil?
    actions
  end

  def create_file(user, path, content, **options)
    actions = create_file_actions(path, content, execute_filemode: options.delete(:execute_filemode))
    commit_files(user, **options.merge(actions: actions))
  end

  def update_file_actions(path, content, previous_path: nil, execute_filemode: nil)
    action = previous_path && previous_path != path ? :move : :update
    actions = [{ action: action, file_path: path, content: content, previous_path: previous_path }]
    actions << { action: :chmod, file_path: path, execute_filemode: execute_filemode } unless execute_filemode.nil?
    actions
  end

  def update_file(user, path, content, **options)
    actions = update_file_actions(path, content, previous_path: options.delete(:previous_path), execute_filemode: options.delete(:execute_filemode))
    commit_files(user, **options.merge(actions: actions))
  end

  def move_dir_files_actions(path, previous_path, branch_name: nil)
    regex = Regexp.new("^#{Regexp.escape(previous_path + '/')}", 'i')
    files = ls_files(branch_name)

    files.each_with_object([]) do |item, list|
      next unless regex.match?(item)

      list.push(
        action: :move,
        file_path: "#{path}/#{item[regex.match(item)[0].size..]}",
        previous_path: item,
        infer_content: true
      )
    end
  end

  def move_dir_files(user, path, previous_path, **options)
    actions = move_dir_files_actions(path, previous_path, branch_name: options[:branch_name])
    return if actions.blank?

    commit_files(user, **options.merge(actions: actions))
  end

  def delete_file(user, path, **options)
    options[:actions] = [{ action: :delete, file_path: path }]

    commit_files(user, **options)
  end

  def with_cache_hooks
    result = yield

    return unless result

    after_create if result.repo_created?
    after_create_branch if result.branch_created?

    result.newrev
  end

  def commit_files(user, **options)
    start_project = options.delete(:start_project)

    if start_project
      options[:start_repository] = start_project.repository.raw_repository
    end

    skip_target_sha = options.delete(:skip_target_sha)
    unless skip_target_sha
      options[:target_sha] = self.commit(options[:branch_name])&.sha
    end

    with_cache_hooks { raw.commit_files(user, **options) }
  end

  def merge(user, source_sha, merge_request, message)
    merge_to_branch(
      user,
      source_sha: source_sha,
      target_branch: merge_request.target_branch,
      message: message
    ) do |commit_id|
      merge_request.update_and_mark_in_progress_merge_commit_sha(commit_id)
      nil # Return value does not matter.
    end
  end

  def merge_to_branch(user, source_sha:, target_branch:, message:, target_sha: nil)
    with_cache_hooks do
      raw_repository.merge(user,
        source_sha: source_sha,
        target_branch: target_branch,
        message: message,
        target_sha: target_sha
      ) do |commit_id|
        yield commit_id if block_given?
      end
    end
  end

  def delete_refs(...)
    raw.delete_refs(...)
  end

  def ff_merge(user, source, target_branch, target_sha: nil, merge_request: nil)
    their_commit_id = commit(source)&.id
    raise 'Invalid merge source' if their_commit_id.nil?

    merge_request&.update_and_mark_in_progress_merge_commit_sha(their_commit_id)

    with_cache_hooks do
      raw.ff_merge(user,
        source_sha: their_commit_id,
        target_branch: target_branch,
        target_sha: target_sha
      )
    end
  end

  def revert(
    user, commit, branch_name, message,
    start_branch_name: nil, start_project: project, dry_run: false)

    with_cache_hooks do
      raw_repository.revert(
        user: user,
        commit: commit.raw,
        branch_name: branch_name,
        message: message,
        start_branch_name: start_branch_name,
        start_repository: start_project.repository.raw_repository,
        dry_run: dry_run
      )
    end
  end

  def cherry_pick(
    user, commit, branch_name, message,
    start_branch_name: nil, start_project: project,
    author_name: nil, author_email: nil, dry_run: false)

    target_sha = find_branch(branch_name)&.dereferenced_target&.id if branch_name.present?

    with_cache_hooks do
      raw_repository.cherry_pick(
        user: user,
        commit: commit.raw,
        branch_name: branch_name,
        message: message,
        start_branch_name: start_branch_name,
        start_repository: start_project.repository.raw_repository,
        author_name: author_name,
        author_email: author_email,
        dry_run: dry_run,
        target_sha: target_sha
      )
    end
  end

  def merged_to_root_ref?(branch_or_name)
    return unless head_commit

    branch = Gitlab::Git::Branch.find(self, branch_or_name)

    if branch
      same_head = branch.target == root_ref_sha
      merged = ancestor?(branch.target, root_ref_sha)
      !same_head && merged
    end
  end

  def root_ref_sha
    @root_ref_sha ||= head_commit.sha
  end

  # If this method is not provided a set of branch names to check merge status,
  # it fetches all branches.
  def merged_branch_names(branch_names = [])
    # Currently we should skip caching if requesting all branch names
    # This is only used in a few places, notably app/services/branches/delete_merged_service.rb,
    # and it could potentially result in a very large cache.
    return raw_repository.merged_branch_names(branch_names) if branch_names.empty?

    cache = redis_hash_cache

    merged_branch_names_hash = cache.fetch_and_add_missing(:merged_branch_names, branch_names) do |missing_branch_names, hash|
      merged = raw_repository.merged_branch_names(missing_branch_names)

      missing_branch_names.each do |bn|
        # Redis only stores strings in hset keys, use a fancy encoder
        hash[bn] = Gitlab::Redis::Boolean.new(merged.include?(bn))
      end
    end

    Set.new(merged_branch_names_hash.select { |_, v| Gitlab::Redis::Boolean.true?(v) }.keys)
  end

  def merge_base(*commits_or_ids)
    commit_ids = commits_or_ids.map do |commit_or_id|
      commit_or_id.is_a?(::Commit) ? commit_or_id.id : commit_or_id
    end

    raw_repository.merge_base(*commit_ids)
  end

  def ancestor?(ancestor_id, descendant_id)
    return false if ancestor_id.nil? || descendant_id.nil?

    cache_key = ancestor_cache_key(ancestor_id, descendant_id)
    request_store_cache.fetch(cache_key) do
      cache.fetch(cache_key) do
        raw_repository.ancestor?(ancestor_id, descendant_id)
      end
    end
  end

  def expire_ancestor_cache(ancestor_id, descendant_id)
    cache_key = ancestor_cache_key(ancestor_id, descendant_id)
    request_store_cache.expire(cache_key)
    cache.expire(cache_key)
  end

  def clone_as_mirror(url, http_authorization_header: "", resolved_address: "")
    import_repository(url, http_authorization_header: http_authorization_header, mirror: true, resolved_address: resolved_address)
  end

  def fetch_as_mirror(url, forced: false, refmap: :all_refs, prune: true, http_authorization_header: "", resolved_address: "")
    fetch_remote(url, refmap: refmap, forced: forced, prune: prune, http_authorization_header: http_authorization_header, resolved_address: resolved_address)
  end

  def fetch_source_branch!(source_repository, source_branch, local_ref)
    raw_repository.fetch_source_branch!(source_repository.raw_repository, source_branch, local_ref)
  end

  def compare_source_branch(target_branch_name, source_repository, source_branch_name, straight:)
    raw_repository.compare_source_branch(target_branch_name, source_repository.raw_repository, source_branch_name, straight: straight)
  end

  def create_ref(ref, ref_path)
    raw_repository.write_ref(ref_path, ref)
  end

  def ls_files(ref)
    actual_ref = ref || root_ref
    raw_repository.ls_files(actual_ref)
  end

  def search_files_by_content(query, ref, options = {})
    return [] if empty? || query.blank?

    raw_repository.search_files_by_content(query, ref, options)
  end

  def search_files_by_name(query, ref)
    return [] if empty?

    raw_repository.search_files_by_name(query, ref)
  end

  def search_files_by_wildcard_path(path, ref = 'HEAD')
    # We need to use RE2 to match Gitaly's regexp engine
    regexp_string = RE2::Regexp.escape(path)

    anything = '.*?'
    anything_but_not_slash = '([^\/])*?'
    regexp_string.gsub!('\*\*', anything)
    regexp_string.gsub!('\*', anything_but_not_slash)

    raw_repository.search_files_by_regexp("^#{regexp_string}$", ref)
  end

  def file_on_head(type, object_type = :blob)
    return unless head = tree(:head)

    objects =
      case object_type
      when :blob
        head.blobs
      when :tree
        head.trees
      else
        raise ArgumentError, "Object type #{object_type} is not supported"
      end

    objects.find do |object|
      Gitlab::FileDetector.type_of(object.path) == type
    end
  end

  def route_map_for(sha)
    blob_data_at(sha, '.gitlab/route-map.yml')
  end

  def lfsconfig_for(sha)
    blob_data_at(sha, '.lfsconfig')
  end

  def has_gitattributes?
    blob_data_at('HEAD', '.gitattributes').present?
  end

  def changelog_config(ref, path)
    blob_data_at(ref, path)
  end

  def fetch_ref(source_repository, source_ref:, target_ref:)
    raw_repository.fetch_ref(source_repository.raw_repository, source_ref: source_ref, target_ref: target_ref)
  end

  def rebase(user, merge_request, skip_ci: false)
    push_options = []
    push_options << Gitlab::PushOptions::CI_SKIP if skip_ci

    raw.rebase(
      user,
      merge_request.id,
      branch: merge_request.source_branch,
      branch_sha: merge_request.source_branch_sha,
      remote_repository: merge_request.target_project.repository.raw,
      remote_branch: merge_request.target_branch,
      push_options: push_options
    ) do |commit_id|
      merge_request.update!(rebase_commit_sha: commit_id, merge_error: nil)
    end
  rescue StandardError => e
    merge_request.update!(rebase_commit_sha: nil)
    raise e
  end

  def squash(user, merge_request, message)
    raw.squash(
      user,
      start_sha: merge_request.diff_start_sha,
      end_sha: merge_request.diff_head_sha,
      author: merge_request.author,
      message: message
    )
  end

  def submodule_links
    @submodule_links ||= ::Gitlab::SubmoduleLinks.new(self)
  end

  def update_submodule(user, submodule, commit_sha, message:, branch:)
    with_cache_hooks do
      raw.update_submodule(
        user: user,
        submodule: submodule,
        commit_sha: commit_sha,
        branch: branch,
        message: message
      )
    end
  end

  def blob_data_at(sha, path)
    blob = blob_at(sha, path)
    return unless blob

    blob.load_all_data!
    blob.data
  end

  def create_if_not_exists(default_branch = nil)
    return if exists?

    raw.create_repository(default_branch)
    after_create

    true
  rescue Gitlab::Git::Repository::RepositoryExists
    # We do not want to call `#after_create` given that we didn't create the
    # repo, but we obviously have a mismatch between what's in our exists cache
    # and actual on-disk state as seen by Gitaly. Let's thus expire our caches.
    expire_status_cache

    nil
  end

  def create_from_bundle(bundle_path)
    raw.create_from_bundle(bundle_path).tap do |result|
      after_create if result
    end
  end

  def blobs_metadata(paths, ref = 'HEAD')
    references = Array.wrap(paths).map { |path| [ref, path] }

    Gitlab::Git::Blob.batch_metadata(raw, references).map { |raw_blob| Blob.decorate(raw_blob) }
  end

  def project
    if container.is_a?(Project)
      container
    else
      container.try(:project)
    end
  end

  # Choose one of the available repository storage options based on a normalized weighted probability.
  # We should always use the latest settings, to avoid picking a deleted shard.
  def self.pick_storage_shard(expire: true)
    Gitlab::CurrentSettings.expire_current_application_settings if expire
    Gitlab::CurrentSettings.pick_repository_storage
  end

  def change_head(branch)
    if branch_exists?(branch)
      before_change_head
      raw_repository.write_ref('HEAD', "refs/heads/#{branch}")
      after_change_head
    else
      container.after_change_head_branch_does_not_exist(branch)

      false
    end
  end

  def cache
    @cache ||= Gitlab::RepositoryCache.new(self)
  end

  def remove_prohibited_refs
    return unless exists?

    patterns = [Gitlab::Git::BRANCH_REF_PREFIX, Gitlab::Git::TAG_REF_PREFIX]

    prohibited_refs = raw_repository.list_refs(patterns).select do |ref|
      ref.name.match(Gitlab::Git::SHA_LIKE_REF)
    end

    return if prohibited_refs.blank?

    raw_repository.delete_refs(*prohibited_refs.map(&:name))
  end

  def get_patch_id(old_revision, new_revision)
    raw_repository.get_patch_id(old_revision, new_revision)
  rescue Gitlab::Git::CommandError, Gitlab::Git::Repository::NoRepository => e
    # This is expected when there are no differences between the old_revision and the new_revision.
    # It's not ideal, but is simpler to handle this here than making breaking changes to gitaly.
    return if e.message.match?(/no difference between old and new revision./)

    Gitlab::ErrorTracking.track_exception(
      e,
      project_id: project.id,
      old_revision: old_revision,
      new_revision: new_revision
    )

    nil
  end

  def object_pool
    gitaly_object_pool = raw.object_pool

    return unless gitaly_object_pool

    source_project = project&.pool_repository&.source_project

    Gitlab::Git::ObjectPool.init_from_gitaly(gitaly_object_pool, source_project&.repository)
  end

  def get_file_attributes(revision, paths, attributes)
    raw_repository
      .get_file_attributes(revision, paths, attributes)
      .map(&:to_h)
  end

  def object_format
    cache_key = "object_format:#{full_path}"

    request_store_cache.fetch(cache_key) do
      case raw.object_format
      when :OBJECT_FORMAT_SHA1
        FORMAT_SHA1
      when :OBJECT_FORMAT_SHA256
        FORMAT_SHA256
      end
    end
  rescue Gitlab::Git::Repository::NoRepository
    nil
  end

  def empty_tree_id
    return Gitlab::Git::SHA1_EMPTY_TREE_ID unless exists?

    case object_format
    when FORMAT_SHA1
      Gitlab::Git::SHA1_EMPTY_TREE_ID
    when FORMAT_SHA256
      Gitlab::Git::SHA256_EMPTY_TREE_ID
    end
  end

  def blank_ref
    return Gitlab::Git::SHA1_BLANK_SHA unless exists?

    case object_format
    when FORMAT_SHA1
      Gitlab::Git::SHA1_BLANK_SHA
    when FORMAT_SHA256
      Gitlab::Git::SHA256_BLANK_SHA
    end
  end

  private

  # Increase the limit by number of excluded refs
  # to prevent a situation when we return less refs than requested
  def adjust_containing_limit(limit:, exclude_refs:)
    return limit if limit == 0

    limit + exclude_refs.size
  end

  # Limit number of returned refs
  # in case the result has more refs than requested
  def adjust_containing_refs(limit:, refs:)
    return refs if limit == 0

    refs.take(limit)
  end

  def ancestor_cache_key(ancestor_id, descendant_id)
    "ancestor:#{ancestor_id}:#{descendant_id}"
  end

  # TODO Genericize finder, later split this on finders by Ref or Oid
  # https://gitlab.com/gitlab-org/gitlab/issues/19877
  def find_commit(oid_or_ref)
    commit = if oid_or_ref.is_a?(Gitlab::Git::Commit)
               oid_or_ref
             else
               Gitlab::Git::Commit.find(raw_repository, oid_or_ref)
             end

    ::Commit.new(commit, container) if commit
  end

  def redis_set_cache
    @redis_set_cache ||= Gitlab::RepositorySetCache.new(self)
  end

  def redis_hash_cache
    @redis_hash_cache ||= Gitlab::RepositoryHashCache.new(self)
  end

  def request_store_cache
    @request_store_cache ||= Gitlab::RepositoryCache.new(self, backend: Gitlab::SafeRequestStore)
  end

  def repository_event(event, tags = {})
    Gitlab::Metrics.add_event(event, tags)
  end

  def initialize_raw_repository
    Gitlab::Git::Repository.new(
      shard,
      disk_path + '.git',
      repo_type.identifier_for_container(container),
      container.full_path,
      container: container
    )
  end
end

Repository.prepend_mod_with('Repository')
