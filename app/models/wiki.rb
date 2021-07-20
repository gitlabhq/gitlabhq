# frozen_string_literal: true

class Wiki
  extend ::Gitlab::Utils::Override
  include HasRepository
  include Repositories::CanHousekeepRepository
  include Gitlab::Utils::StrongMemoize
  include GlobalID::Identification

  extend ActiveModel::Naming

  MARKUPS = { # rubocop:disable Style/MultilineIfModifier
    'Markdown' => :markdown,
    'RDoc'     => :rdoc,
    'AsciiDoc' => :asciidoc,
    'Org'      => :org
  }.freeze unless defined?(MARKUPS)

  CouldNotCreateWikiError = Class.new(StandardError)

  HOMEPAGE = 'home'
  SIDEBAR = '_sidebar'

  TITLE_ORDER = 'title'
  CREATED_AT_ORDER = 'created_at'
  DIRECTION_DESC = 'desc'
  DIRECTION_ASC = 'asc'

  attr_reader :container, :user

  # Returns a string describing what went wrong after
  # an operation fails.
  attr_reader :error_message

  # Support run_after_commit callbacks, since we don't have a DB record
  # we delegate to the container.
  delegate :run_after_commit, to: :container

  class << self
    attr_accessor :container_class

    def for_container(container, user = nil)
      "#{container.class.name}Wiki".constantize.new(container, user)
    end

    # This is needed to support repository lookup through Gitlab::GlRepository::Identifier
    def find_by_id(container_id)
      container_class.find_by_id(container_id)&.wiki
    end
  end

  def initialize(container, user = nil)
    raise ArgumentError, "user must be a User, got #{user.class}" if user && !user.is_a?(User)

    @container = container
    @user = user
  end

  def ==(other)
    other.is_a?(self.class) && container == other.container
  end

  # This is needed in:
  # - Storage::Hashed
  # - Gitlab::GlRepository::RepoType#identifier_for_container
  #
  # We also need an `#id` to support `build_stubbed` in tests, where the
  # value doesn't matter.
  #
  # NOTE: Wikis don't have a DB record, so this ID can be the same
  # for two wikis in different containers and should not be expected to
  # be unique. Use `to_global_id` instead if you need a unique ID.
  def id
    container.id
  end

  def path
    container.path + '.wiki'
  end

  # Returns the Gitlab::Git::Wiki object.
  def wiki
    strong_memoize(:wiki) do
      create_wiki_repository
      Gitlab::Git::Wiki.new(repository.raw)
    end
  end

  def create_wiki_repository
    repository.create_if_not_exists
    change_head_to_default_branch

    raise CouldNotCreateWikiError unless repository_exists?
  rescue StandardError => err
    Gitlab::ErrorTracking.track_exception(err, wiki: {
      container_type: container.class.name,
      container_id: container.id,
      full_path: full_path,
      disk_path: disk_path
    })

    raise CouldNotCreateWikiError
  end

  def has_home_page?
    !!find_page(HOMEPAGE)
  end

  def empty?
    !repository_exists? || list_pages(limit: 1).empty?
  end

  def exists?
    !empty?
  end

  # Lists wiki pages of the repository.
  #
  # limit - max number of pages returned by the method.
  # sort - criterion by which the pages are sorted.
  # direction - order of the sorted pages.
  # load_content - option, which specifies whether the content inside the page
  #                will be loaded.
  #
  # Returns an Array of GitLab WikiPage instances or an
  # empty Array if this Wiki has no pages.
  def list_pages(limit: 0, sort: nil, direction: DIRECTION_ASC, load_content: false)
    wiki.list_pages(
      limit: limit,
      sort: sort,
      direction_desc: direction == DIRECTION_DESC,
      load_content: load_content
    ).map do |page|
      WikiPage.new(self, page)
    end
  end

  def sidebar_entries(limit: Gitlab::WikiPages::MAX_SIDEBAR_PAGES, **options)
    pages = list_pages(**options.merge(limit: limit + 1))
    limited = pages.size > limit
    pages = pages.first(limit) if limited

    [WikiDirectory.group_pages(pages), limited]
  end

  # Finds a page within the repository based on a title
  # or slug.
  #
  # title - The human readable or parameterized title of
  #         the page.
  #
  # Returns an initialized WikiPage instance or nil
  def find_page(title, version = nil)
    page_title, page_dir = page_title_and_dir(title)

    if page = wiki.page(title: page_title, version: version, dir: page_dir)
      WikiPage.new(self, page)
    end
  end

  def find_sidebar(version = nil)
    find_page(SIDEBAR, version)
  end

  def find_file(name, version = 'HEAD', load_content: true)
    data_limit = load_content ? -1 : 0
    blobs = repository.blobs_at([[version, name]], blob_size_limit: data_limit)

    return if blobs.empty?

    Gitlab::Git::WikiFile.new(blobs.first)
  end

  def create_page(title, content, format = :markdown, message = nil)
    commit = commit_details(:created, message, title)

    wiki.write_page(title, format.to_sym, content, commit)
    repository.expire_status_cache if repository.empty?
    after_wiki_activity

    true
  rescue Gitlab::Git::Wiki::DuplicatePageError => e
    @error_message = "Duplicate page: #{e.message}"
    false
  end

  def update_page(page, content:, title: nil, format: :markdown, message: nil)
    commit = commit_details(:updated, message, page.title)

    wiki.update_page(page.path, title || page.name, format.to_sym, content, commit)
    after_wiki_activity

    true
  end

  def delete_page(page, message = nil)
    return unless page

    capture_git_error(:deleted) do
      repository.delete_file(user, page.path, **multi_commit_options(:deleted, message, page.title))

      after_wiki_activity

      true
    end
  end

  def page_title_and_dir(title)
    return unless title

    title_array = title.split("/")
    title = title_array.pop
    [title, title_array.join("/")]
  end

  def ensure_repository
    raise CouldNotCreateWikiError unless wiki.repository_exists?
  end

  def hook_attrs
    {
      web_url: web_url,
      git_ssh_url: ssh_url_to_repo,
      git_http_url: http_url_to_repo,
      path_with_namespace: full_path,
      default_branch: default_branch
    }
  end

  override :repository
  def repository
    @repository ||= Gitlab::GlRepository::WIKI.repository_for(self)
  end

  def repository_storage
    raise NotImplementedError
  end

  def hashed_storage?
    raise NotImplementedError
  end

  override :full_path
  def full_path
    container.full_path + '.wiki'
  end

  # @deprecated use full_path when you need it for an URL route or disk_path when you want to point to the filesystem
  alias_method :path_with_namespace, :full_path

  override :default_branch
  def default_branch
    super || Gitlab::Git::Wiki.default_ref(container)
  end

  def wiki_base_path
    web_url(only_path: true).sub(%r{/#{Wiki::HOMEPAGE}\z}, '')
  end

  # Callbacks for synchronous processing after wiki changes.
  # These will be executed after any change made through GitLab itself (web UI and API),
  # but not for Git pushes.
  def after_wiki_activity
  end

  # Callbacks for background processing after wiki changes.
  # These will be executed after any change to the wiki repository.
  def after_post_receive
  end

  override :git_garbage_collect_worker_klass
  def git_garbage_collect_worker_klass
    Wikis::GitGarbageCollectWorker
  end

  def cleanup
    @repository = nil
  end

  def capture_git_error(action, &block)
    yield block
  rescue Gitlab::Git::Index::IndexError,
         Gitlab::Git::CommitError,
         Gitlab::Git::PreReceiveError,
         Gitlab::Git::CommandError,
         ArgumentError => error

    Gitlab::ErrorTracking.log_exception(error, action: action, wiki_id: id)

    false
  end

  private

  def multi_commit_options(action, message = nil, title = nil)
    commit_message = build_commit_message(action, message, title)
    git_user = Gitlab::Git::User.from_gitlab(user)

    {
      branch_name: repository.root_ref,
      message: commit_message,
      author_email: git_user.email,
      author_name: git_user.name
    }
  end

  def commit_details(action, message = nil, title = nil)
    commit_message = build_commit_message(action, message, title)
    git_user = Gitlab::Git::User.from_gitlab(user)

    Gitlab::Git::Wiki::CommitDetails.new(user.id,
                                         git_user.username,
                                         git_user.name,
                                         git_user.email,
                                         commit_message)
  end

  def build_commit_message(action, message, title)
    message.presence || default_message(action, title)
  end

  def default_message(action, title)
    "#{user.username} #{action} page: #{title}"
  end

  def change_head_to_default_branch
    # If the wiki has commits in the 'HEAD' branch means that the current
    # HEAD is pointing to the right branch. If not, it could mean that either
    # the repo has just been created or that 'HEAD' is pointing
    # to the wrong branch and we need to rewrite it
    return if repository.raw_repository.commit_count('HEAD') != 0

    repository.raw_repository.write_ref('HEAD', "refs/heads/#{default_branch}")
  end
end

Wiki.prepend_mod_with('Wiki')
