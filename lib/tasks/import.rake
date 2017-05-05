require 'benchmark'
require 'rainbow/ext/string'

class GithubImport
  def self.run!(*args)
    new(*args).run!
  end

  def initialize(token, gitlab_username, project_path, extras)
    @options = { url: 'https://api.github.com', token: token, verbose: true }
    @project_path = project_path
    @current_user = User.find_by_username(gitlab_username)
    @github_repo = extras.empty? ? nil : extras.first
  end

  def run!
    @repo = GithubRepos.new(@options, @current_user, @github_repo).choose_one!

    raise 'No repo found!' unless @repo

    show_warning!

    @project = Project.find_by_full_path(@project_path) || new_project

    import!
  end

  private

  def show_warning!
    puts "This will import GitHub #{@repo['full_name'].bright} into GitLab #{@project_path.bright} as #{@current_user.name}"
    puts "Permission checks are ignored. Press any key to continue.".color(:red)

    STDIN.getch

    puts 'Starting the import (this could take a while)'.color(:green)
  end

  def import!
    @project.import_start

    timings = Benchmark.measure do
      Github::Import.new(@project, @options).execute
    end

    puts "Import finished. Timings: #{timings}".color(:green)

    @project.import_finish
  end

  def new_project
    Project.transaction do
      namespace_path, _sep, name = @project_path.rpartition('/')
      namespace = find_or_create_namespace(namespace_path)

      Projects::CreateService.new(
        @current_user,
        name: name,
        path: name,
        description: @repo['description'],
        namespace_id: namespace.id,
        visibility_level: visibility_level,
        import_type: 'github',
        import_source: @repo['full_name'],
        skip_wiki: @repo['has_wiki']
      ).execute
    end
  end

  def find_or_create_namespace(names)
    return @current_user.namespace if names == @current_user.namespace_path
    return @current_user.namespace unless @current_user.can_create_group?

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
    @repo['private'] ? Gitlab::VisibilityLevel::PRIVATE : current_application_settings.default_project_visibility
  end
end

class GithubRepos
  def initialize(options, current_user, github_repo)
    @options = options
    @current_user = current_user
    @github_repo = github_repo
  end

  def choose_one!
    return found_github_repo if @github_repo

    repos.each do |repo|
      print "ID: #{repo['id'].to_s.bright}".color(:green)
      print "\tName: #{repo['full_name']}\n".color(:green)
    end

    print 'ID? '.bright

    repos.find { |repo| repo['id'] == repo_id }
  end

  def found_github_repo
    repos.find { |repo| repo['full_name'] == @github_repo }
  end

  def repo_id
    @repo_id ||= STDIN.gets.chomp.to_i
  end

  def repos
    Github::Repositories.new(@options).fetch
  end
end

namespace :import do
  desc 'Import a GitHub project - Example: import:github[ToKeN,root,root/blah,my/github_repo] (optional my/github_repo)'
  task :github, [:token, :gitlab_username, :project_path] => :environment do |_t, args|
    abort 'Project path must be: namespace(s)/project_name'.color(:red) unless args.project_path.include?('/')

    GithubImport.run!(args.token, args.gitlab_username, args.project_path, args.extras)
  end
end
