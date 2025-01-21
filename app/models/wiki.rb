# frozen_string_literal: true

class Wiki
  extend ::Gitlab::Utils::Override
  include HasRepository
  include ::Repositories::CanHousekeepRepository
  include Gitlab::Utils::StrongMemoize
  include GlobalID::Identification
  include Gitlab::Git::WrapsGitalyErrors

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
  TEMPLATES_DIR = 'templates'
  REDIRECTS_YML = '.gitlab/redirects.yml'

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

    def sluggified_full_path(title, extension)
      sluggified_title(title) + '.' + extension
    end

    def sluggified_title(title)
      title = Gitlab::EncodingHelper.encode_utf8_no_detect(title.to_s.strip)
      title = File.absolute_path(title, '/')
      title = Pathname.new(title).relative_path_from('/').to_s
      title.tr(' ', '-')
    end

    def canonicalize_filename(filename)
      ::File.basename(filename, ::File.extname(filename)).tr('-', ' ')
    end

    def cname(name, char_white_sub = '-', char_other_sub = '-')
      name.to_s.gsub(/\s/, char_white_sub).gsub(/[<>+]/, char_other_sub)
    end

    def preview_slug(title, format)
      ext = format == :markdown ? "md" : format.to_s
      name = cname(title) + '.' + ext
      canonical_name = canonicalize_filename(name)

      path =
        if name.include?('/')
          name.sub(%r{/[^/]+$}, '/')
        else
          ''
        end

      path + cname(canonical_name, '-', '-')
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
  # - Gitlab::Repositories::RepoType#identifier_for_container
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

  def create_wiki_repository
    repository.create_if_not_exists(default_branch)

    raise CouldNotCreateWikiError unless repository_exists?
  rescue StandardError => e
    Gitlab::ErrorTracking.track_exception(e, wiki: {
      container_type: container.class.name,
      container_id: container.id,
      full_path: full_path,
      disk_path: disk_path
    })

    raise CouldNotCreateWikiError
  end

  def has_home_page?
    !!find_page(HOMEPAGE)
  rescue StandardError
    false
  end

  def empty?
    capture_git_error(:empty, response_on_error: true) do
      !repository_exists? || list_page_paths(limit: 1).empty?
    end
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
  def list_pages(
    direction: DIRECTION_ASC,
    load_content: false,
    size_limit: Gitlab::Git::Blob::MAX_DATA_DISPLAY_SIZE,
    limit: 0,
    offset: 0
  )
    capture_git_error(:list, response_on_error: []) do
      create_wiki_repository unless repository_exists?

      paths = list_page_paths(limit: limit, offset: offset)
      next [] if paths.empty?

      pages = paths.map do |path|
        page = Gitlab::Git::WikiPage.new(
          url_path: strip_extension(path),
          title: canonicalize_filename(path),
          format: find_page_format(path),
          path: path,
          raw_data: '',
          name: canonicalize_filename(path),
          historical: false
        )
        WikiPage.new(self, page)
      end
      sort_pages!(pages, direction)
      pages = pages.take(limit) if limit > 0
      fetch_pages_content!(pages, size_limit: size_limit) if load_content

      pages
    end
  end

  # Finds a page within the repository based on a title
  # or slug.
  #
  # title - The human readable or parameterized title of
  #         the page.
  #
  # Returns an initialized WikiPage instance or nil
  def find_page(title, version = nil, load_content: true)
    return unless title.present?

    capture_git_error(:find, response_on_error: nil) do
      create_wiki_repository unless repository_exists?

      version = version.presence || default_branch
      path = find_matched_file(title, version)
      next if path.blank?

      path = Gitlab::EncodingHelper.encode_utf8_no_detect(path)
      blob_options = load_content ? {} : { limit: 0 }
      blob = repository.blob_at(version, path, **blob_options)
      commit = repository.commit(blob.commit_id)
      format = find_page_format(path)

      page = Gitlab::Git::WikiPage.new(
        url_path: strip_extension(path),
        title: canonicalize_filename(path),
        format: format,
        path: path,
        raw_data: blob.data,
        name: canonicalize_filename(path),
        historical: version == default_branch ? false : check_page_historical(path, commit),
        version: Gitlab::Git::WikiPageVersion.new(commit, format)
      )
      WikiPage.new(self, page)
    end
  end

  def find_sidebar(version = nil)
    find_page(SIDEBAR, version)
  end

  def find_file(name, version = default_branch, load_content: true)
    data_limit = load_content ? -1 : 0
    blobs = capture_git_error(:blob, response_on_error: []) do
      repository.blobs_at([[version, name]], blob_size_limit: data_limit)
    end

    return if blobs.empty?

    Gitlab::Git::WikiFile.new(blobs.first)
  end

  def create_page(title, content, format = :markdown, message = nil)
    with_valid_format(format) do |default_extension|
      sanitized_path = sluggified_full_path(title, default_extension)

      capture_git_error(:created) do
        # cannot create two pages with:
        # - the same title but different format
        # - the same title but different capitalization
        # - the same title, different capitalization, and different format
        next duplicated_page_error(sanitized_path) if file_exists_by_regex?(title)

        create_wiki_repository unless repository_exists?
        sanitized_path = sluggified_full_path(title, default_extension)
        options = multi_commit_options(:created, message, title)
        actions =
          repository.create_file_actions(sanitized_path, content) +
          update_redirection_actions(sluggified_title(title))

        repository.commit_files(user, **options.merge({ actions: actions }))

        repository.expire_status_cache if repository.empty?
        after_wiki_activity

        true
      rescue Gitlab::Git::Index::IndexError
        duplicated_page_error(sanitized_path)
      end
    end
  end

  def update_page(page, content:, title: nil, format: :markdown, message: nil)
    with_valid_format(format) do |default_extension|
      title = title.presence || Pathname(page.path).sub_ext('').to_s

      # If the format is the same we keep the former extension. This check is for formats
      # that can have more than one extension like Markdown (.md, .markdown)
      # If we don't do this we will override the existing extension.
      extension = page.format != format.to_sym ? default_extension : File.extname(page.path).downcase[1..]

      capture_git_error(:updated) do
        create_wiki_repository unless repository_exists?
        sanitized_path = sluggified_full_path(title, extension)
        options = multi_commit_options(:updated, message, title)
        new_url_path = sluggified_title(title)
        branch = repository.root_ref || default_branch
        actions =
          repository.update_file_actions(sanitized_path, content, previous_path: page.path) +
          repository.move_dir_files_actions(new_url_path, page.url_path, branch_name: branch) +
          update_redirection_actions(new_url_path, page.url_path)

        repository.commit_files(user, **options.merge(actions: actions))

        after_wiki_activity

        true
      rescue Gitlab::Git::Index::IndexError
        duplicated_page_error(sanitized_path)
      end
    end
  end

  def delete_page(page, message = nil)
    return unless page

    capture_git_error(:deleted) do
      create_wiki_repository unless repository_exists?
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
    capture_git_error(:default_branch, response_on_error: 'main') do
      super || Gitlab::DefaultBranch.value(object: container)
    end
  end

  def wiki_base_path
    web_url(only_path: true).sub(%r{/#{Wiki::HOMEPAGE}\z}o, '')
  end

  # Callbacks for synchronous processing after wiki changes.
  # These will be executed after any change made through GitLab itself (web UI and API),
  # but not for Git pushes.
  def after_wiki_activity; end

  # Callbacks for background processing after wiki changes.
  # These will be executed after any change to the wiki repository.
  def after_post_receive; end

  override :git_garbage_collect_worker_klass
  def git_garbage_collect_worker_klass
    Wikis::GitGarbageCollectWorker
  end

  def cleanup
    @repository = nil
  end

  private

  def capture_git_error(action, response_on_error: false, &block)
    wrapped_gitaly_errors(&block)
  rescue Gitlab::Git::Index::IndexError,
    Gitlab::Git::CommitError,
    Gitlab::Git::PreReceiveError,
    Gitlab::Git::CommandError,
    ArgumentError => e

    @error_message = e.message

    Gitlab::ErrorTracking.log_exception(e, action: action, wiki_id: id)

    response_on_error
  end

  def update_redirection_actions(new_path, old_path = nil, **options)
    return [] unless old_path != new_path

    old_contents = repository.blob_at(default_branch, REDIRECTS_YML)
    redirects = old_contents ? YAML.safe_load(old_contents.data).to_h : {}
    redirects[old_path] = new_path if old_path
    redirects.except!(new_path)
    new_contents = YAML.dump(redirects)

    if old_contents
      repository.update_file_actions(REDIRECTS_YML, new_contents)
    else
      repository.create_file_actions(REDIRECTS_YML, new_contents)
    end
  end

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

    find_matched_file(title, default_branch).present?
  end

  def duplicated_page_error(file)
    @error_message = format(
      _("Duplicate page: A page with that title already exists in the file %{file}"),
      file: file)

    false
  end

  def sluggified_full_path(title, extension)
    self.class.sluggified_full_path(title, extension)
  end

  def sluggified_title(title)
    self.class.sluggified_title(title)
  end

  def canonicalize_filename(filename)
    self.class.canonicalize_filename(filename)
  end

  def find_matched_file(title, version)
    find_file_by_title(title, version) ||
      find_file_by_title(sluggified_title(title), version)
  end

  def find_file_by_title(title, version)
    escaped_path = RE2::Regexp.escape(title)
    path_regexp = Gitlab::EncodingHelper.encode_utf8_no_detect("(?i)^#{escaped_path}\\.(#{file_extension_regexp})$")

    matched_files = capture_git_error(:find, response_on_error: []) do
      repository.search_files_by_regexp(path_regexp, version, limit: 1)
    end
    matched_files.first
  end

  def find_page_format(path)
    ext = File.extname(path).downcase[1..]
    MARKUPS.find { |_, markup| markup[:extension_regex].match?(ext) }&.first
  end

  def check_page_historical(path, commit)
    repository.last_commit_for_path(default_branch, path)&.id != commit&.id
  end

  def file_extension_regexp
    # We could not use ALLOWED_EXTENSIONS_REGEX constant or similar regexp with
    # Regexp.union. The result combination complicated modifiers:
    # /(?i-mx:md|mkdn?|mdown|markdown)|(?i-mx:rdoc).../
    # Regexp used by Gitaly is Go's Regexp package. It does not support those
    # features. So, we have to compose another more-friendly regexp to pass to
    # Gitaly side.
    Wiki::MARKUPS.map { |_, format| format[:extension_regex].source }.join("|")
  end

  def strip_extension(path)
    path.sub(/\.[^.]+\z/, "")
  end

  def list_page_paths(limit: 0, offset: 0)
    return [] if repository.empty?

    path_regexp = Gitlab::EncodingHelper.encode_utf8_no_detect("(?i)\\.(#{file_extension_regexp})$")
    repository.search_files_by_regexp(path_regexp, default_branch, limit: limit, offset: offset)
  end

  # After migrating to normal repository RPCs, it's very expensive to sort the
  # pages by created_at. We have to either ListLastCommitsForTree RPC call or
  # N+1 LastCommitForPath. Either are efficient for a large repository.
  # Therefore, we decide to sort the title only.
  def sort_pages!(pages, direction)
    # Sort by path to ensure the files inside a sub-folder are grouped and sorted together
    pages.sort_by!(&:path)
    pages.reverse! if direction == DIRECTION_DESC
  end

  def fetch_pages_content!(pages, size_limit: Gitlab::Git::Blob::MAX_DATA_DISPLAY_SIZE)
    blobs =
      repository
      .blobs_at(pages.map { |page| [default_branch, page.path] }, blob_size_limit: size_limit)
      .to_h { |blob| [blob.path, blob.data] }

    pages.each do |page|
      page.raw_content = blobs[page.path]
    end
  end
end

Wiki.prepend_mod_with('Wiki')
