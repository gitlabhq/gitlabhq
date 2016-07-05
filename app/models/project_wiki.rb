class ProjectWiki
  include Gitlab::ShellAdapter
  include Elastic::WikiRepositoriesSearch
  include Gitlab::CurrentSettings

  MARKUPS = {
    'Markdown' => :markdown,
    'RDoc'     => :rdoc,
    'AsciiDoc' => :asciidoc
  } unless defined?(MARKUPS)

  class CouldNotCreateWikiError < StandardError; end

  # Returns a string describing what went wrong after
  # an operation fails.
  attr_reader :error_message
  attr_reader :project

  def initialize(project, user = nil)
    @project = project
    @user = user
  end

  def path
    @project.path + '.wiki'
  end

  def path_with_namespace
    @project.path_with_namespace + ".wiki"
  end

  def web_url
    Gitlab::Routing.url_helpers.namespace_project_wiki_url(@project.namespace, @project, :home)
  end

  def url_to_repo
    gitlab_shell.url_to_repo(path_with_namespace)
  end

  def ssh_url_to_repo
    url_to_repo
  end

  def http_url_to_repo
    [Gitlab.config.gitlab.url, "/", path_with_namespace, ".git"].join('')
  end

  def wiki_base_path
    [Gitlab.config.gitlab.relative_url_root, "/", @project.path_with_namespace, "/wikis"].join('')
  end

  # Returns the Gollum::Wiki object.
  def wiki
    @wiki ||= begin
      Gollum::Wiki.new(path_to_repo)
    rescue Rugged::OSError
      create_repo!
    end
  end

  def repository_exists?
    !!repository.exists?
  end

  def empty?
    pages.empty?
  end

  # Returns an Array of Gitlab WikiPage instances or an
  # empty Array if this Wiki has no pages.
  def pages
    wiki.pages.map { |page| WikiPage.new(self, page, true) }
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
    if page = wiki.page(page_title, version, page_dir)
      WikiPage.new(self, page, true)
    else
      nil
    end
  end

  def find_file(name, version = nil, try_on_disk = true)
    version = wiki.ref if version.nil? # Gollum::Wiki#file ?
    if wiki_file = wiki.file(name, version, try_on_disk)
      wiki_file
    else
      nil
    end
  end

  def create_page(title, content, format = :markdown, message = nil)
    commit = commit_details(:created, message, title)

    wiki.write_page(title, format.to_sym, content, commit)

    update_elastic_index

    update_project_activity
  rescue Gollum::DuplicatePageError => e
    @error_message = "Duplicate page: #{e.message}"
    return false
  end

  def update_page(page, content, format = :markdown, message = nil)
    commit = commit_details(:updated, message, page.title)

    wiki.update_page(page, page.name, format.to_sym, content, commit)

    update_elastic_index

    update_project_activity
  end

  def delete_page(page, message = nil)
    wiki.delete_page(page, commit_details(:deleted, message, page.title))

    update_elastic_index

    update_project_activity
  end

  def page_title_and_dir(title)
    title_array = title.split("/")
    title = title_array.pop
    [title, title_array.join("/")]
  end

  def search_files(query)
    repository.search_files(query, default_branch)
  end

  def repository
    @repository ||= Repository.new(path_with_namespace, @project)
  end

  def default_branch
    wiki.class.default_ref
  end

  def create_repo!
    if init_repo(path_with_namespace)
      wiki = Gollum::Wiki.new(path_to_repo)
    else
      raise CouldNotCreateWikiError
    end

    repository.after_create

    wiki
  end

  def hook_attrs
    {
      web_url: web_url,
      git_ssh_url: ssh_url_to_repo,
      git_http_url: http_url_to_repo,
      path_with_namespace: path_with_namespace,
      default_branch: default_branch
    }
  end

  private

  def init_repo(path_with_namespace)
    gitlab_shell.add_repository(project.repository_storage_path, path_with_namespace)
  end

  def commit_details(action, message = nil, title = nil)
    commit_message = message || default_message(action, title)

    { email: @user.email, name: @user.name, message: commit_message }
  end

  def default_message(action, title)
    "#{@user.username} #{action} page: #{title}"
  end

  def path_to_repo
    @path_to_repo ||= File.join(project.repository_storage_path, "#{path_with_namespace}.git")
  end

  def update_project_activity
    @project.touch(:last_activity_at)
  end

  def update_elastic_index
    index_blobs if current_application_settings.elasticsearch_indexing?
  end
end
