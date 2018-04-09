class ProjectWiki
  include Gitlab::ShellAdapter
  include Storage::LegacyProjectWiki

  MARKUPS = {
    'Markdown' => :markdown,
    'RDoc'     => :rdoc,
    'AsciiDoc' => :asciidoc
  }.freeze unless defined?(MARKUPS)

  CouldNotCreateWikiError = Class.new(StandardError)

  # Returns a string describing what went wrong after
  # an operation fails.
  attr_reader :error_message
  attr_reader :project

  def initialize(project, user = nil)
    @project = project
    @user = user
  end

  delegate :empty?, to: :pages
  delegate :repository_storage_path, :hashed_storage?, to: :project

  def path
    @project.path + '.wiki'
  end

  def full_path
    @project.full_path + '.wiki'
  end

  # @deprecated use full_path when you need it for an URL route or disk_path when you want to point to the filesystem
  alias_method :path_with_namespace, :full_path

  def web_url
    Gitlab::Routing.url_helpers.project_wiki_url(@project, :home)
  end

  def url_to_repo
    gitlab_shell.url_to_repo(full_path)
  end

  def ssh_url_to_repo
    url_to_repo
  end

  def http_url_to_repo
    "#{Gitlab.config.gitlab.url}/#{full_path}.git"
  end

  def wiki_base_path
    [Gitlab.config.gitlab.relative_url_root, '/', @project.full_path, '/wikis'].join('')
  end

  # Returns the Gitlab::Git::Wiki object.
  def wiki
    @wiki ||= begin
      gl_repository = Gitlab::GlRepository.gl_repository(project, true)
      raw_repository = Gitlab::Git::Repository.new(project.repository_storage, disk_path + '.git', gl_repository)

      create_repo!(raw_repository) unless raw_repository.exists?

      Gitlab::Git::Wiki.new(raw_repository)
    end
  end

  def repository_exists?
    !!repository.exists?
  end

  def has_home_page?
    !!find_page('home')
  end

  # Returns an Array of Gitlab WikiPage instances or an
  # empty Array if this Wiki has no pages.
  def pages(limit: nil)
    wiki.pages(limit: limit).map { |page| WikiPage.new(self, page, true) }
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
      WikiPage.new(self, page, true)
    end
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
    return false
  rescue Gitlab::Git::Wiki::OperationError => e
    @error_message = "Error performing the operation: #{e.message}"
    return false
  end

  def update_page(page, content:, title: nil, format: :markdown, message: nil)
    commit = commit_details(:updated, message, page.title)

    wiki.update_page(page.path, title || page.name, format.to_sym, content, commit)

    update_project_activity
  rescue Gitlab::Git::Wiki::OperationError => e
    @error_message = "Error performing the operation: #{e.message}"
    return false
  end

  def delete_page(page, message = nil)
    return unless page

    wiki.delete_page(page.path, commit_details(:deleted, message, page.title))

    update_project_activity
  rescue Gitlab::Git::Wiki::OperationError => e
    @error_message = "Error performing the operation: #{e.message}"
    return false
  end

  def page_formatted_data(page)
    page_title, page_dir = page_title_and_dir(page.title)

    wiki.page_formatted_data(title: page_title, dir: page_dir, version: page.version)
  end

  def page_title_and_dir(title)
    return unless title

    title_array = title.split("/")
    title = title_array.pop
    [title, title_array.join("/")]
  end

  def search_files(query)
    repository.search_files_by_content(query, default_branch)
  end

  def repository
    @repository ||= Repository.new(full_path, @project, disk_path: disk_path, is_wiki: true)
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

  def create_repo!(raw_repository)
    gitlab_shell.create_repository(project.repository_storage, disk_path)

    raise CouldNotCreateWikiError unless raw_repository.exists?

    repository.after_create
  end

  def commit_details(action, message = nil, title = nil)
    commit_message = message || default_message(action, title)

    Gitlab::Git::Wiki::CommitDetails.new(@user.id,
                                         @user.username,
                                         @user.name,
                                         @user.email,
                                         commit_message)
  end

  def default_message(action, title)
    "#{@user.username} #{action} page: #{title}"
  end

  def update_project_activity
    @project.touch(:last_activity_at, :last_repository_updated_at)
  end
end
