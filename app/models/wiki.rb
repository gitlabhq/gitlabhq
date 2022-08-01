# frozen_string_literal: true

class Wiki
  extend ::Gitlab::Utils::Override
  include HasRepository
  include Repositories::CanHousekeepRepository
  include Gitlab::Utils::StrongMemoize
  include GlobalID::Identification

  extend ActiveModel::Naming

  MARKUPS = { # rubocop:disable Style/MultilineIfModifier
    markdown: {
      name: 'Markdown',
      default_extension: :md,
      extension_regex: Regexp.new('md|mkdn?|mdown|markdown', 'i'),
      created_by_user: true
    },
    rdoc: {
      name: 'RDoc',
      default_extension: :rdoc,
      extension_regex: Regexp.new('rdoc', 'i'),
      created_by_user: true
    },
    asciidoc: {
      name: 'AsciiDoc',
      default_extension: :asciidoc,
      extension_regex: Regexp.new('adoc|asciidoc', 'i'),
      created_by_user: true
    },
    org: {
      name: 'Org',
      default_extension: :org,
      extension_regex: Regexp.new('org', 'i'),
      created_by_user: true
    },
    textile: {
      name: 'Textile',
      default_extension: :textile,
      extension_regex: Regexp.new('textile', 'i')
    },
    creole: {
      name: 'Creole',
      default_extension: :creole,
      extension_regex: Regexp.new('creole', 'i')
    },
    rest: {
      name: 'reStructuredText',
      default_extension: :rst,
      extension_regex: Regexp.new('re?st(\.txt)?', 'i')
    },
    mediawiki: {
      name: 'MediaWiki',
      default_extension: :mediawiki,
      extension_regex: Regexp.new('(media)?wiki', 'i')
    },
    pod: {
      name: 'Pod',
      default_extension: :pod,
      extension_regex: Regexp.new('pod', 'i')
    },
    plaintext: {
      name: 'Plain Text',
      default_extension: :txt,
      extension_regex: Regexp.new('txt', 'i')
    }
  }.freeze unless defined?(MARKUPS)

  VALID_USER_MARKUPS = MARKUPS.select { |_, v| v[:created_by_user] }.freeze unless defined?(VALID_USER_MARKUPS)

  unless defined?(ALLOWED_EXTENSIONS_REGEX)
    ALLOWED_EXTENSIONS_REGEX = Regexp.union(MARKUPS.map { |key, value| value[:extension_regex] }).freeze
  end

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
    repository.create_if_not_exists(default_branch)

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
  def find_page(title, version = nil, load_content: true)
    page_title, page_dir = page_title_and_dir(title)

    if page = wiki.page(title: page_title, version: version, dir: page_dir, load_content: load_content)
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
    with_valid_format(format) do |default_extension|
      if file_exists_by_regex?(title)
        raise_duplicate_page_error!
      end

      capture_git_error(:created) do
        create_wiki_repository unless repository_exists?
        sanitized_path = sluggified_full_path(title, default_extension)
        repository.create_file(user, sanitized_path, content, **multi_commit_options(:created, message, title))
        repository.expire_status_cache if repository.empty?
        after_wiki_activity

        true
      rescue Gitlab::Git::Index::IndexError
        raise_duplicate_page_error!
      end
    end
  rescue Gitlab::Git::Wiki::DuplicatePageError => e
    @error_message = _("Duplicate page: %{error_message}" % { error_message: e.message })

    false
  end

  def update_page(page, content:, title: nil, format: :markdown, message: nil)
    with_valid_format(format) do |default_extension|
      title = title.presence || Pathname(page.path).sub_ext('').to_s

      # If the format is the same we keep the former extension. This check is for formats
      # that can have more than one extension like Markdown (.md, .markdown)
      # If we don't do this we will override the existing extension.
      extension = page.format != format.to_sym ? default_extension : File.extname(page.path).downcase[1..]

      capture_git_error(:updated) do
        repository.update_file(
          user,
          sluggified_full_path(title, extension),
          content,
          previous_path: page.path,
          **multi_commit_options(:updated, message, title))

        after_wiki_activity

        true
      end
    end
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
    web_url(only_path: true).sub(%r{/#{Wiki::HOMEPAGE}\z}o, '')
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
      branch_name: repository.root_ref || default_branch,
      message: commit_message,
      author_email: git_user.email,
      author_name: git_user.name
    }
  end

  def build_commit_message(action, message, title)
    message.presence || default_message(action, title)
  end

  def default_message(action, title)
    "#{user.username} #{action} page: #{title}"
  end

  def with_valid_format(format, &block)
    default_extension = Wiki::VALID_USER_MARKUPS.dig(format.to_sym, :default_extension).to_s

    if default_extension.blank?
      @error_message = _('Invalid format selected')

      return false
    end

    yield default_extension
  end

  def file_exists_by_regex?(title)
    return false unless repository_exists?

    escaped_title = Regexp.escape(sluggified_title(title))
    regex = Regexp.new("^#{escaped_title}\.#{ALLOWED_EXTENSIONS_REGEX}$", 'i')

    repository.ls_files('HEAD').any? { |s| s =~ regex }
  end

  def raise_duplicate_page_error!
    raise Gitlab::Git::Wiki::DuplicatePageError, _('A page with that title already exists')
  end

  def sluggified_full_path(title, extension)
    sluggified_title(title) + '.' + extension
  end

  def sluggified_title(title)
    utf8_encoded_title = Gitlab::EncodingHelper.encode_utf8_no_detect(title)

    sanitized_title(utf8_encoded_title).tr(' ', '-')
  end

  def sanitized_title(title)
    clean_absolute_path = File.expand_path(title, '/')

    Pathname.new(clean_absolute_path).relative_path_from('/').to_s
  end
end

Wiki.prepend_mod_with('Wiki')
