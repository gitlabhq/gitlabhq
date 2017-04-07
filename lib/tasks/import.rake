require 'benchmark'
require 'rainbow/ext/string'
require_relative '../gitlab/shell_adapter'
require_relative '../gitlab/github_import/importer'

class NewImporter < ::Gitlab::GithubImport::Importer
  def execute
    # Same as ::Gitlab::GithubImport::Importer#execute, but showing some progress.
    puts 'Importing repository...'.color(:aqua)
    import_repository unless project.repository_exists?

    puts 'Importing labels...'.color(:aqua)
    import_labels

    puts 'Importing milestones...'.color(:aqua)
    import_milestones

    puts 'Importing pull requests...'.color(:aqua)
    import_pull_requests

    puts 'Importing issues...'.color(:aqua)
    import_issues

    puts 'Importing issue comments...'.color(:aqua)
    import_comments(:issues)

    puts 'Importing pull request comments...'.color(:aqua)
    import_comments(:pull_requests)

    puts 'Importing wiki...'.color(:aqua)
    import_wiki

    # Gitea doesn't have a Release API yet
    # See https://github.com/go-gitea/gitea/issues/330
    unless project.gitea_import?
      import_releases
    end

    handle_errors

    project.repository.after_import
    project.import_finish

    true
  end

  def import_repository
    begin
      raise 'Blocked import URL.' if Gitlab::UrlBlocker.blocked_url?(project.import_url)

      project.create_repository
      project.repository.add_remote(project.import_type, project.import_url)
      project.repository.set_remote_as_mirror(project.import_type)
      project.repository.fetch_remote(project.import_type, forced: true)
      project.repository.remove_remote(project.import_type)
    rescue => e
      # Expire cache to prevent scenarios such as:
      # 1. First import failed, but the repo was imported successfully, so +exists?+ returns true
      # 2. Retried import, repo is broken or not imported but +exists?+ still returns true
      project.repository.expire_content_cache if project.repository_exists?

      raise "Error importing repository #{project.import_url} into #{project.path_with_namespace} - #{e.message}"
    end
  end
end

class GithubImport
  def self.run!(*args)
    new(*args).run!
  end

  def initialize(token, gitlab_username, project_path, extras)
    @token = token
    @project_path = project_path
    @current_user = User.find_by_username(gitlab_username)
    @github_repo = extras.empty? ? nil : extras.first
  end

  def run!
    @repo = GithubRepos.new(@token, @current_user, @github_repo).choose_one!

    raise 'No repo found!' unless @repo

    show_warning!

    @project = Project.find_by_full_path(@project_path) || new_project

    import!
  end

  private

  def show_warning!
    puts "This will import GH #{@repo.full_name.bright} into GL #{@project_path.bright} as #{@current_user.name}"
    puts "Permission checks are ignored. Press any key to continue.".color(:red)

    STDIN.getch

    puts 'Starting the import...'.color(:green)
  end

  def import!
    import_url = @project.import_url.gsub(/\:\/\/(.*@)?/, "://#{@token}@")
    @project.update(import_url: import_url)

    @project.import_start

    timings = Benchmark.measure do
      NewImporter.new(@project).execute
    end

    puts "Import finished. Timings: #{timings}".color(:green)
  end

  def new_project
    Project.transaction do
      namespace_path, _sep, name = @project_path.rpartition('/')
      namespace = find_or_create_namespace(namespace_path)

      Project.create!(
        import_url: "https://#{@token}@github.com/#{@repo.full_name}.git",
        name: name,
        path: name,
        description: @repo.description,
        namespace: namespace,
        visibility_level: visibility_level,
        import_type: 'github',
        import_source: @repo.full_name,
        creator: @current_user
      )
    end
  end

  def find_or_create_namespace(names)
    return @current_user.namespace if names == @current_user.namespace_path
    return @current_user.namespace unless @current_user.can_create_group?

    names = params[:target_namespace].presence || names
    full_path_namespace = Namespace.find_by_full_path(names)

    return full_path_namespace if full_path_namespace

    names.split('/').inject(nil) do |parent, name|
      begin
        namespace = Group.create!(name: name,
                                  path: name,
                                  owner: @current_user,
                                  parent: parent)
        namespace.add_owner(@current_user)

        namespace
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
        Namespace.where(parent: parent).find_by_path_or_name(name)
      end
    end
  end

  def full_path_namespace(names)
    @full_path_namespace ||= Namespace.find_by_full_path(names)
  end

  def visibility_level
    @repo.private ? Gitlab::VisibilityLevel::PRIVATE : current_application_settings.default_project_visibility
  end
end

class GithubRepos
  def initialize(token, current_user, github_repo)
    @token = token
    @current_user = current_user
    @github_repo = github_repo
  end

  def choose_one!
    return found_github_repo if @github_repo

    repos.each do |repo|
      print "ID: #{repo[:id].to_s.bright} ".color(:green)
      puts "- Name: #{repo[:full_name]}".color(:green)
    end

    print 'ID? '.bright

    repos.find { |repo| repo[:id] == repo_id }
  end

  def found_github_repo
    repos.find { |repo| repo[:full_name] == @github_repo }
  end

  def repo_id
    @repo_id ||= STDIN.gets.chomp.to_i
  end

  def repos
    @repos ||= client.repos
  end

  def client
    @client ||= Gitlab::GithubImport::Client.new(@token, {})
  end
end

namespace :import do
  desc 'Import a GitHub project - Example: import:github[ToKeN,root,root/blah,my/github_repo] (optional my/github_repo)'
  task :github, [:token, :gitlab_username, :project_path] => :environment do |_t, args|
    abort 'Project path must be: namespace(s)/project_name'.color(:red) unless args.project_path.include?('/')

    GithubImport.run!(args.token, args.gitlab_username, args.project_path, args.extras)
  end
end
