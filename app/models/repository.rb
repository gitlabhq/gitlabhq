require 'securerandom'

class Repository
  REF_MERGE_REQUEST = 'merge-requests'.freeze
  REF_KEEP_AROUND = 'keep-around'.freeze
  REF_ENVIRONMENTS = 'environments'.freeze
  MAX_DIVERGING_COUNT = 1000

  RESERVED_REFS_NAMES = %W[
    heads
    tags
    replace
    #{REF_ENVIRONMENTS}
    #{REF_KEEP_AROUND}
    #{REF_ENVIRONMENTS}
  ].freeze

  include Gitlab::ShellAdapter
  include Gitlab::RepositoryCacheAdapter

  attr_accessor :full_path, :disk_path, :project, :is_wiki

  delegate :ref_name_for_sha, to: :raw_repository
  delegate :bundle_to_disk, :create_from_bundle, to: :raw_repository

  CreateTreeError = Class.new(StandardError)

  # Methods that cache data from the Git repository.
  #
  # Each entry in this Array should have a corresponding method with the exact
  # same name. The cache key used by those methods must also match method's
  # name.
  #
  # For example, for entry `:commit_count` there's a method called `commit_count` which
  # stores its data in the `commit_count` cache key.
  CACHED_METHODS = %i(size commit_count rendered_readme contribution_guide
                      changelog license_blob license_key gitignore koding_yml
                      gitlab_ci_yml branch_names tag_names branch_count
                      tag_count avatar exists? root_ref has_visible_content?
                      issue_template_names merge_request_template_names).freeze

  # Methods that use cache_method but only memoize the value
  MEMOIZED_CACHED_METHODS = %i(license).freeze

  # Certain method caches should be refreshed when certain types of files are
  # changed. This Hash maps file types (as returned by Gitlab::FileDetector) to
  # the corresponding methods to call for refreshing caches.
  METHOD_CACHES_FOR_FILE_TYPES = {
    readme: :rendered_readme,
    changelog: :changelog,
    license: %i(license_blob license_key license),
    contributing: :contribution_guide,
    gitignore: :gitignore,
    koding: :koding_yml,
    gitlab_ci: :gitlab_ci_yml,
    avatar: :avatar,
    issue_template: :issue_template_names,
    merge_request_template: :merge_request_template_names
  }.freeze

  def initialize(full_path, project, disk_path: nil, is_wiki: false)
    @full_path = full_path
    @disk_path = disk_path || full_path
    @project = project
    @commit_cache = {}
    @is_wiki = is_wiki
  end

  def ==(other)
    @disk_path == other.disk_path
  end

  def raw_repository
    return nil unless full_path

    @raw_repository ||= initialize_raw_repository
  end

  alias_method :raw, :raw_repository

  def cleanup
    @raw_repository&.cleanup
  end

  # Return absolute path to repository
  def path_to_repo
    @path_to_repo ||= File.expand_path(
      File.join(repository_storage_path, disk_path + '.git')
    )
  end

  def inspect
    "#<#{self.class.name}:#{@disk_path}>"
  end

  def create_hooks
    Gitlab::Git::Repository.create_hooks(path_to_repo, Gitlab.config.gitlab_shell.hooks_path)
  end

  def commit(ref = 'HEAD')
    return nil unless exists?
    return ref if ref.is_a?(::Commit)

    find_commit(ref)
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
      Commit.decorate(commits, @project)
    else
      []
    end
  end

  def commits(ref = nil, path: nil, limit: nil, offset: nil, skip_merges: false, after: nil, before: nil, all: nil)
    options = {
      repo: raw_repository,
      ref: ref,
      path: path,
      limit: limit,
      offset: offset,
      after: after,
      before: before,
      follow: Array(path).length == 1,
      skip_merges: skip_merges,
      all: all
    }

    commits = Gitlab::Git::Commit.where(options)
    commits = Commit.decorate(commits, @project) if commits.present?

    CommitCollection.new(project, commits, ref)
  end

  def commits_between(from, to)
    commits = Gitlab::Git::Commit.between(raw_repository, from, to)
    commits = Commit.decorate(commits, @project) if commits.present?
    commits
  end

  # Returns a list of commits that are not present in any reference
  def new_commits(newrev)
    refs = ::Gitlab::Git::RevList.new(raw, newrev: newrev).new_refs

    refs.map { |sha| commit(sha.strip) }
  end

  # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/384
  def find_commits_by_message(query, ref = nil, path = nil, limit = 1000, offset = 0)
    unless exists? && has_visible_content? && query.present?
      return []
    end

    commits = raw_repository.find_commits_by_message(query, ref, path, limit, offset).map do |c|
      commit(c)
    end
    CommitCollection.new(project, commits, ref)
  end

  def find_branch(name, fresh_repo: true)
    raw_repository.find_branch(name, fresh_repo)
  end

  def find_tag(name)
    tags.find { |tag| tag.name == name }
  end

  def add_branch(user, branch_name, ref)
    branch = raw_repository.add_branch(branch_name, user: user, target: ref)

    after_create_branch

    branch
  rescue Gitlab::Git::Repository::InvalidRef
    false
  end

  def add_tag(user, tag_name, target, message = nil)
    raw_repository.add_tag(tag_name, user: user, target: target, message: message)
  rescue Gitlab::Git::Repository::InvalidRef
    false
  end

  def rm_branch(user, branch_name)
    before_remove_branch

    raw_repository.rm_branch(branch_name, user: user)

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

    branch_names.include?(branch_name)
  end

  def tag_exists?(tag_name)
    return false unless raw_repository

    tag_names.include?(tag_name)
  end

  def ref_exists?(ref)
    !!raw_repository&.ref_exists?(ref)
  rescue ArgumentError
    false
  end

  # Makes sure a commit is kept around when Git garbage collection runs.
  # Git GC will delete commits from the repository that are no longer in any
  # branches or tags, but we want to keep some of these commits around, for
  # example if they have comments or CI builds.
  def keep_around(sha)
    return unless sha.present? && commit_by(oid: sha)

    return if kept_around?(sha)

    # This will still fail if the file is corrupted (e.g. 0 bytes)
    raw_repository.write_ref(keep_around_ref_name(sha), sha, shell: false)
  rescue Gitlab::Git::CommandError => ex
    Rails.logger.error "Unable to create keep-around reference for repository #{path}: #{ex}"
  end

  def kept_around?(sha)
    ref_exists?(keep_around_ref_name(sha))
  end

  def diverging_commit_counts(branch)
    @root_ref_hash ||= raw_repository.commit(root_ref).id
    cache.fetch(:"diverging_commit_counts_#{branch.name}") do
      # Rugged seems to throw a `ReferenceError` when given branch_names rather
      # than SHA-1 hashes
      number_commits_behind, number_commits_ahead =
        raw_repository.count_commits_between(
          @root_ref_hash,
          branch.dereferenced_target.sha,
          left_right: true,
          max_count: MAX_DIVERGING_COUNT)

      { behind: number_commits_behind, ahead: number_commits_ahead }
    end
  end

  def expire_tags_cache
    expire_method_caches(%i(tag_names tag_count))
    @tags = nil
  end

  def expire_branches_cache
    expire_method_caches(%i(branch_names branch_count has_visible_content?))
    @local_branches = nil
    @branch_exists_memo = nil
  end

  def expire_statistics_caches
    expire_method_caches(%i(size commit_count))
  end

  def expire_all_method_caches
    expire_method_caches(CACHED_METHODS)
  end

  def expire_avatar_cache
    expire_method_caches(%i(avatar))
  end

  # Refreshes the method caches of this repository.
  #
  # types - An Array of file types (e.g. `:readme`) used to refresh extra
  #         caches.
  def refresh_method_caches(types)
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
    expire_method_caches(%i(root_ref))
  end

  # Expires the cache(s) used to determine if a repository is empty or not.
  def expire_emptiness_caches
    return unless empty?

    expire_method_caches(%i(has_visible_content?))
  end

  def lookup_cache
    @lookup_cache ||= {}
  end

  def expire_exists_cache
    expire_method_caches(%i(exists?))
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

  # Runs code after a repository has been created.
  def after_create
    expire_exists_cache
    expire_root_ref_cache
    expire_emptiness_caches

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
  def before_push_tag
    expire_statistics_caches
    expire_emptiness_caches
    expire_tags_cache

    repository_event(:push_tag)
  end

  # Runs code before removing a tag.
  def before_remove_tag
    expire_tags_cache
    expire_statistics_caches

    repository_event(:remove_tag)
  end

  # Runs code after removing a tag.
  def after_remove_tag
    expire_tags_cache
  end

  # Runs code after the HEAD of a repository is changed.
  def after_change_head
    expire_method_caches(METHOD_CACHES_FOR_FILE_TYPES.keys)
  end

  # Runs code after a repository has been forked/imported.
  def after_import
    expire_content_cache
  end

  # Runs code after a new commit has been pushed.
  def after_push_commit(branch_name)
    expire_statistics_caches
    expire_branch_cache(branch_name)

    repository_event(:push_commit, branch: branch_name)
  end

  # Runs code after a new branch has been created.
  def after_create_branch
    expire_branches_cache

    repository_event(:push_branch)
  end

  # Runs code before removing an existing branch.
  def before_remove_branch
    expire_branches_cache

    repository_event(:remove_branch)
  end

  # Runs code after an existing branch has been removed.
  def after_remove_branch
    expire_branches_cache
  end

  def method_missing(m, *args, &block)
    if m == :lookup && !block_given?
      lookup_cache[m] ||= {}
      lookup_cache[m][args.join(":")] ||= raw_repository.__send__(m, *args, &block) # rubocop:disable GitlabSecurity/PublicSend
    else
      raw_repository.__send__(m, *args, &block) # rubocop:disable GitlabSecurity/PublicSend
    end
  end

  def respond_to_missing?(method, include_private = false)
    raw_repository.respond_to?(method, include_private) || super
  end

  def blob_at(sha, path)
    Blob.decorate(raw_repository.blob_at(sha, path), project)
  rescue Gitlab::Git::Repository::NoRepository
    nil
  end

  # items is an Array like: [[oid, path], [oid1, path1]]
  def blobs_at(items)
    raw_repository.batch_blobs(items).map { |blob| Blob.decorate(blob, project) }
  end

  def root_ref
    # When the repo does not exist, or there is no root ref, we raise this error so no data is cached.
    raw_repository&.root_ref or raise Gitlab::Git::Repository::NoRepository # rubocop:disable Style/AndOr
  end
  cache_method :root_ref

  # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/314
  def exists?
    return false unless full_path

    raw_repository.exists?
  end
  cache_method :exists?

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

  def commit_count
    root_ref ? raw_repository.commit_count(root_ref) : 0
  end
  cache_method :commit_count, fallback: 0

  def commit_count_for_ref(ref)
    return 0 unless exists?

    cache.fetch(:"commit_count_#{ref}") { raw_repository.commit_count(ref) }
  end

  delegate :branch_names, to: :raw_repository
  cache_method :branch_names, fallback: []

  delegate :tag_names, to: :raw_repository
  cache_method :tag_names, fallback: []

  delegate :branch_count, :tag_count, :has_visible_content?, to: :raw_repository
  cache_method :branch_count, fallback: 0
  cache_method :tag_count, fallback: 0
  cache_method :has_visible_content?, fallback: false

  def avatar
    # n+1: https://gitlab.com/gitlab-org/gitlab-ce/issues/38327
    Gitlab::GitalyClient.allow_n_plus_1_calls do
      if tree = file_on_head(:avatar)
        tree.path
      end
    end
  end
  cache_method :avatar

  def issue_template_names
    Gitlab::Template::IssueTemplate.dropdown_names(project)
  end
  cache_method :issue_template_names, fallback: []

  def merge_request_template_names
    Gitlab::Template::MergeRequestTemplate.dropdown_names(project)
  end
  cache_method :merge_request_template_names, fallback: []

  def readme
    if readme = tree(:head)&.readme
      ReadmeBlob.new(readme, self)
    end
  end

  def rendered_readme
    MarkupHelper.markup_unsafe(readme.name, readme.data, project: project) if readme
  end
  cache_method :rendered_readme

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
    return unless exists?

    raw_repository.license_short_name
  end
  cache_method :license_key

  def license
    return unless license_key

    Licensee::License.new(license_key)
  end
  cache_method :license, memoize_only: true

  def gitignore
    file_on_head(:gitignore)
  end
  cache_method :gitignore

  def koding_yml
    file_on_head(:koding)
  end
  cache_method :koding_yml

  def gitlab_ci_yml
    file_on_head(:gitlab_ci)
  end
  cache_method :gitlab_ci_yml

  def head_commit
    @head_commit ||= commit(self.root_ref)
  end

  def head_tree
    if head_commit
      @head_tree ||= Tree.new(self, head_commit.sha, nil)
    end
  end

  def tree(sha = :head, path = nil, recursive: false)
    if sha == :head
      return unless head_commit

      if path.nil?
        return head_tree
      else
        sha = head_commit.sha
      end
    end

    Tree.new(self, sha, path, recursive: recursive)
  end

  def blob_at_branch(branch_name, path)
    last_commit = commit(branch_name)

    if last_commit
      blob_at(last_commit.sha, path)
    else
      nil
    end
  end

  def last_commit_for_path(sha, path)
    commit = raw_repository.last_commit_for_path(sha, path)
    ::Commit.new(commit, @project) if commit
  end

  def last_commit_id_for_path(sha, path)
    key = path.blank? ? "last_commit_id_for_path:#{sha}" : "last_commit_id_for_path:#{sha}:#{Digest::SHA1.hexdigest(path)}"

    cache.fetch(key) do
      last_commit_for_path(sha, path)&.id
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

  def branches_sorted_by(value)
    raw_repository.local_branches(sort_by: value)
  end

  def tags_sorted_by(value)
    case value
    when 'name_asc'
      VersionSorter.sort(tags) { |tag| tag.name }
    when 'name_desc'
      VersionSorter.rsort(tags) { |tag| tag.name }
    when 'updated_desc'
      tags_sorted_by_committed_date.reverse
    when 'updated_asc'
      tags_sorted_by_committed_date
    else
      tags
    end
  end

  # Params:
  #
  # order_by: name|email|commits
  # sort: asc|desc default: 'asc'
  def contributors(order_by: nil, sort: 'asc')
    commits = self.commits(nil, limit: 2000, offset: 0, skip_merges: true)

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

  def branch_names_contains(sha)
    raw_repository.branch_names_contains_sha(sha)
  end

  def tag_names_contains(sha)
    raw_repository.tag_names_contains_sha(sha)
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

    multi_action(user, **options)
  end

  def create_file(user, path, content, **options)
    options[:actions] = [{ action: :create, file_path: path, content: content }]

    multi_action(user, **options)
  end

  def update_file(user, path, content, **options)
    previous_path = options.delete(:previous_path)
    action = previous_path && previous_path != path ? :move : :update

    options[:actions] = [{ action: action, file_path: path, previous_path: previous_path, content: content }]

    multi_action(user, **options)
  end

  def delete_file(user, path, **options)
    options[:actions] = [{ action: :delete, file_path: path }]

    multi_action(user, **options)
  end

  def with_cache_hooks
    result = yield

    return unless result

    after_create if result.repo_created?
    after_create_branch if result.branch_created?

    result.newrev
  end

  def multi_action(user, **options)
    start_project = options.delete(:start_project)

    if start_project
      options[:start_repository] = start_project.repository.raw_repository
    end

    with_cache_hooks { raw.multi_action(user, **options) }
  end

  def merge(user, source_sha, merge_request, message)
    with_cache_hooks do
      raw_repository.merge(user, source_sha, merge_request.target_branch, message) do |commit_id|
        merge_request.update(in_progress_merge_commit_sha: commit_id)
        nil # Return value does not matter.
      end
    end
  end

  def ff_merge(user, source, target_branch, merge_request: nil)
    their_commit_id = commit(source)&.id
    raise 'Invalid merge source' if their_commit_id.nil?

    merge_request&.update(in_progress_merge_commit_sha: their_commit_id)

    with_cache_hooks { raw.ff_merge(user, their_commit_id, target_branch) }
  end

  def revert(
    user, commit, branch_name, message,
    start_branch_name: nil, start_project: project)

    with_cache_hooks do
      raw_repository.revert(
        user: user,
        commit: commit.raw,
        branch_name: branch_name,
        message: message,
        start_branch_name: start_branch_name,
        start_repository: start_project.repository.raw_repository
      )
    end
  end

  def cherry_pick(
    user, commit, branch_name, message,
    start_branch_name: nil, start_project: project)

    with_cache_hooks do
      raw_repository.cherry_pick(
        user: user,
        commit: commit.raw,
        branch_name: branch_name,
        message: message,
        start_branch_name: start_branch_name,
        start_repository: start_project.repository.raw_repository
      )
    end
  end

  def merged_to_root_ref?(branch_or_name)
    branch = Gitlab::Git::Branch.find(self, branch_or_name)

    if branch
      same_head = branch.target == root_ref_sha
      merged = ancestor?(branch.target, root_ref_sha)
      !same_head && merged
    else
      nil
    end
  end

  def root_ref_sha
    @root_ref_sha ||= commit(root_ref).sha
  end

  delegate :merged_branch_names, :can_be_merged?, to: :raw_repository

  def merge_base(first_commit_id, second_commit_id)
    first_commit_id = commit(first_commit_id).try(:id) || first_commit_id
    second_commit_id = commit(second_commit_id).try(:id) || second_commit_id
    raw_repository.merge_base(first_commit_id, second_commit_id)
  end

  def ancestor?(ancestor_id, descendant_id)
    return false if ancestor_id.nil? || descendant_id.nil?

    raw_repository.ancestor?(ancestor_id, descendant_id)
  end

  def fetch_as_mirror(url, forced: false, refmap: :all_refs, remote_name: nil, prune: true)
    unless remote_name
      remote_name = "tmp-#{SecureRandom.hex}"
      tmp_remote_name = true
    end

    add_remote(remote_name, url, mirror_refmap: refmap)
    fetch_remote(remote_name, forced: forced, prune: prune)
  ensure
    remove_remote(remote_name) if tmp_remote_name
  end

  def fetch_remote(remote, forced: false, ssh_auth: nil, no_tags: false, prune: true)
    gitlab_shell.fetch_remote(raw_repository, remote, ssh_auth: ssh_auth, forced: forced, no_tags: no_tags, prune: prune)
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

  def search_files_by_content(query, ref)
    return [] if empty? || query.blank?

    raw_repository.search_files_by_content(query, ref)
  end

  def search_files_by_name(query, ref)
    return [] if empty?

    raw_repository.search_files_by_name(query, ref)
  end

  def copy_gitattributes(ref)
    actual_ref = ref || root_ref
    begin
      raw_repository.copy_gitattributes(actual_ref)
      true
    rescue Gitlab::Git::Repository::InvalidRef
      false
    end
  end

  def file_on_head(type)
    if head = tree(:head)
      head.blobs.find do |blob|
        Gitlab::FileDetector.type_of(blob.path) == type
      end
    end
  end

  def route_map_for(sha)
    blob_data_at(sha, '.gitlab/route-map.yml')
  end

  def gitlab_ci_yml_for(sha, path = '.gitlab-ci.yml')
    blob_data_at(sha, path)
  end

  def fetch_ref(source_repository, source_ref:, target_ref:)
    raw_repository.fetch_ref(source_repository.raw_repository, source_ref: source_ref, target_ref: target_ref)
  end

  def repository_storage_path
    @project.repository_storage_path
  end

  def rebase(user, merge_request)
    raw.rebase(user, merge_request.id, branch: merge_request.source_branch,
                                       branch_sha: merge_request.source_branch_sha,
                                       remote_repository: merge_request.target_project.repository.raw,
                                       remote_branch: merge_request.target_branch)
  end

  private

  # TODO Generice finder, later split this on finders by Ref or Oid
  # gitlab-org/gitlab-ce#39239
  def find_commit(oid_or_ref)
    commit = if oid_or_ref.is_a?(Gitlab::Git::Commit)
               oid_or_ref
             else
               Gitlab::Git::Commit.find(raw_repository, oid_or_ref)
             end

    ::Commit.new(commit, @project) if commit
  end

  def blob_data_at(sha, path)
    blob = blob_at(sha, path)
    return unless blob

    blob.load_all_data!
    blob.data
  end

  def cache
    @cache ||= Gitlab::RepositoryCache.new(self)
  end

  def tags_sorted_by_committed_date
    tags.sort_by do |tag|
      # Annotated tags can point to any object (e.g. a blob), but generally
      # tags point to a commit. If we don't have a commit, then just default
      # to putting the tag at the end of the list.
      target = tag.dereferenced_target

      if target
        target.committed_date
      else
        Time.now
      end
    end
  end

  def keep_around_ref_name(sha)
    "refs/#{REF_KEEP_AROUND}/#{sha}"
  end

  def repository_event(event, tags = {})
    Gitlab::Metrics.add_event(event, { path: full_path }.merge(tags))
  end

  def initialize_raw_repository
    Gitlab::Git::Repository.new(project.repository_storage, disk_path + '.git', Gitlab::GlRepository.gl_repository(project, is_wiki))
  end
end
