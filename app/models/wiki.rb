# frozen_string_literal: true

class Wiki
  extend ::Gitlab::Utils::Override
  include HasRepository
  include Gitlab::Utils::StrongMemoize

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

  def self.for_container(container, user = nil)
    "#{container.class.name}Wiki".constantize.new(container, user)
  end

  def initialize(container, user = nil)
    @container = container
    @user = user
  end

  def path
    container.path + '.wiki'
  end

  # Returns the Gitlab::Git::Wiki object.
  def wiki
    strong_memoize(:wiki) do
      repository.create_if_not_exists
      raise CouldNotCreateWikiError unless repository_exists?

      Gitlab::Git::Wiki.new(repository.raw)
    end
  rescue => err
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
    list_pages(limit: 1).empty?
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

  # Finds a page within the repository based on a tile
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

  def find_file(name, version = nil)
    wiki.file(name, version)
  end

  def create_page(title, content, format = :markdown, message = nil)
    commit = commit_details(:created, message, title)

    wiki.write_page(title, format.to_sym, content, commit)

    update_container_activity
  rescue Gitlab::Git::Wiki::DuplicatePageError => e
    @error_message = "Duplicate page: #{e.message}"
    false
  end

  def update_page(page, content:, title: nil, format: :markdown, message: nil)
    commit = commit_details(:updated, message, page.title)

    wiki.update_page(page.path, title || page.name, format.to_sym, content, commit)

    update_container_activity
  end

  def delete_page(page, message = nil)
    return unless page

    wiki.delete_page(page.path, commit_details(:deleted, message, page.title))

    update_container_activity
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
    @repository ||= Repository.new(full_path, container, shard: repository_storage, disk_path: disk_path, repo_type: Gitlab::GlRepository::WIKI)
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
  alias_method :id, :full_path

  # @deprecated use full_path when you need it for an URL route or disk_path when you want to point to the filesystem
  alias_method :path_with_namespace, :full_path

  override :default_branch
  def default_branch
    wiki.class.default_ref
  end

  def wiki_base_path
    Gitlab.config.gitlab.relative_url_root + web_url(only_path: true).sub(%r{/#{Wiki::HOMEPAGE}\z}, '')
  end

  private

  def commit_details(action, message = nil, title = nil)
    commit_message = message.presence || default_message(action, title)
    git_user = Gitlab::Git::User.from_gitlab(user)

    Gitlab::Git::Wiki::CommitDetails.new(user.id,
                                         git_user.username,
                                         git_user.name,
                                         git_user.email,
                                         commit_message)
  end

  def default_message(action, title)
    "#{user.username} #{action} page: #{title}"
  end

  def update_container_activity
    container.after_wiki_activity
  end
end

Wiki.prepend_if_ee('EE::Wiki')
