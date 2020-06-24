# frozen_string_literal: true

class ProjectWiki
  include Storage::LegacyProjectWiki
  include Gitlab::Utils::StrongMemoize

  MARKUPS = {
    'Markdown' => :markdown,
    'RDoc'     => :rdoc,
    'AsciiDoc' => :asciidoc,
    'Org'      => :org
  }.freeze unless defined?(MARKUPS)

  CouldNotCreateWikiError = Class.new(StandardError)
  SIDEBAR = '_sidebar'

  TITLE_ORDER = 'title'
  CREATED_AT_ORDER = 'created_at'
  DIRECTION_DESC = 'desc'
  DIRECTION_ASC = 'asc'

  attr_reader :project, :user

  # Returns a string describing what went wrong after
  # an operation fails.
  attr_reader :error_message

  def initialize(project, user = nil)
    @project = project
    @user = user
  end

  delegate :repository_storage, :hashed_storage?, to: :project

  def path
    @project.path + '.wiki'
  end

  def full_path
    @project.full_path + '.wiki'
  end
  alias_method :id, :full_path

  # @deprecated use full_path when you need it for an URL route or disk_path when you want to point to the filesystem
  alias_method :path_with_namespace, :full_path

  def web_url(only_path: nil)
    Gitlab::UrlBuilder.build(self, only_path: only_path)
  end

  def url_to_repo
    ssh_url_to_repo
  end

  def ssh_url_to_repo
    Gitlab::RepositoryUrlBuilder.build(repository.full_path, protocol: :ssh)
  end

  def http_url_to_repo
    Gitlab::RepositoryUrlBuilder.build(repository.full_path, protocol: :http)
  end

  def wiki_base_path
    [Gitlab.config.gitlab.relative_url_root, '/', @project.full_path, '/-', '/wikis'].join('')
  end

  # Returns the Gitlab::Git::Wiki object.
  def wiki
    strong_memoize(:wiki) do
      repository.create_if_not_exists
      raise CouldNotCreateWikiError unless repository_exists?

      Gitlab::Git::Wiki.new(repository.raw)
    end
  rescue => err
    Gitlab::ErrorTracking.track_exception(err, project_wiki: { project_id: project.id, full_path: full_path, disk_path: disk_path })
    raise CouldNotCreateWikiError
  end

  def repository_exists?
    !!repository.exists?
  end

  def has_home_page?
    !!find_page('home')
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

  def sidebar_entries(limit: Gitlab::WikiPages::MAX_SIDEBAR_PAGES, **options)
    pages = list_pages(**options.merge(limit: limit + 1))
    limited = pages.size > limit
    pages = pages.first(limit) if limited

    [WikiPage.group_by_directory(pages), limited]
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

    update_project_activity
  rescue Gitlab::Git::Wiki::DuplicatePageError => e
    @error_message = "Duplicate page: #{e.message}"
    false
  end

  def update_page(page, content:, title: nil, format: :markdown, message: nil)
    commit = commit_details(:updated, message, page.title)

    wiki.update_page(page.path, title || page.name, format.to_sym, content, commit)

    update_project_activity
  end

  def delete_page(page, message = nil)
    return unless page

    wiki.delete_page(page.path, commit_details(:deleted, message, page.title))

    update_project_activity
  end

  def page_title_and_dir(title)
    return unless title

    title_array = title.split("/")
    title = title_array.pop
    [title, title_array.join("/")]
  end

  def repository
    @repository ||= Repository.new(full_path, @project, shard: repository_storage, disk_path: disk_path, repo_type: Gitlab::GlRepository::WIKI)
  end

  def default_branch
    wiki.class.default_ref
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

  def update_project_activity
    @project.touch(:last_activity_at, :last_repository_updated_at)
  end
end

ProjectWiki.prepend_if_ee('EE::ProjectWiki')
