# frozen_string_literal: true

require 'benchmark'
require 'rainbow/ext/string'

class GithubImport
  def self.run!(*args)
    new(*args).run!
  end

  def initialize(token, gitlab_username, project_path, extras)
    @options = { token: token }
    @project_path = project_path
    @current_user = UserFinder.new(gitlab_username).find_by_username

    raise "GitLab user #{gitlab_username} not found. Please specify a valid username." unless @current_user

    @github_repo = extras.empty? ? nil : extras.first
  end

  def run!
    @repo = GithubRepos
      .new(@options[:token], @current_user, @github_repo)
      .choose_one!

    raise 'No repo found!' unless @repo

    show_warning!

    @project = Project.find_by_full_path(@project_path) || new_project

    import!
  end

  private

  def show_warning!
    puts "This will import GitHub #{@repo.full_name.bright} into GitLab #{@project_path.bright} as #{@current_user.name}"
    puts "Permission checks are ignored. Press any key to continue.".color(:red)

    $stdin.getch

    puts 'Starting the import (this could take a while)'.color(:green)
  end

  def import!
    @project.import_state.force_start

    import_success = false

    timings = Benchmark.measure do
      import_success = Gitlab::GithubImport::SequentialImporter
        .new(@project, token: @options[:token])
        .execute
    end

    if import_success
      @project.after_import
      puts "Import finished. Timings: #{timings}".color(:green)
    else
      puts "Import was not successful. Errors were as follows:"
      puts @project.import_state.last_error
    end
  end

  def new_project
    Project.transaction do
      namespace_path, _sep, name = @project_path.rpartition('/')
      namespace = find_or_create_namespace(namespace_path)

      project = Projects::CreateService.new(
        @current_user,
        name: name,
        path: name,
        description: @repo.description,
        namespace_id: namespace.id,
        visibility_level: visibility_level,
        skip_wiki: @repo.has_wiki
      ).execute

      project.update!(
        import_type: 'github',
        import_source: @repo.full_name,
        import_url: @repo.clone_url.sub('://', "://#{@options[:token]}@")
      )

      project
    end
  end

  def find_or_create_namespace(names)
    return @current_user.namespace if names == @current_user.namespace_path
    return @current_user.namespace unless @current_user.can_create_group?

    Groups::NestedCreateService.new(@current_user, group_path: names).execute
  end

  def full_path_namespace(names)
    @full_path_namespace ||= Namespace.find_by_full_path(names)
  end

  def visibility_level
    @repo.private ? Gitlab::VisibilityLevel::PRIVATE : Gitlab::CurrentSettings.current_application_settings.default_project_visibility
  end
end

class GithubRepos
  def initialize(token, current_user, github_repo)
    @client = Gitlab::GithubImport::Client.new(token)
    @client.octokit.auto_paginate = true

    @current_user = current_user
    @github_repo = github_repo
  end

  def choose_one!
    return found_github_repo if @github_repo

    repos.each do |repo|
      print "ID: #{repo.id.to_s.bright}".color(:green)
      print "\tName: #{repo.full_name}\n".color(:green)
    end

    print 'ID? '.bright

    repos.find { |repo| repo.id == repo_id }
  end

  def found_github_repo
    repos.find { |repo| repo.full_name == @github_repo }
  end

  def repo_id
    @repo_id ||= $stdin.gets.chomp.to_i
  end

  def repos
    @client.octokit.list_repositories
  end
end

namespace :import do
  desc 'GitLab | Import | Import a GitHub project - Example: import:github[ToKeN,root,root/blah,my/github_repo] (optional my/github_repo)'
  task :github, [:token, :gitlab_username, :project_path] => :environment do |_t, args|
    abort 'Project path must be: namespace(s)/project_name'.color(:red) unless args.project_path.include?('/')

    GithubImport.run!(args.token, args.gitlab_username, args.project_path, args.extras)
  end
end
