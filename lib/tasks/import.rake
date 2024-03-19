# frozen_string_literal: true

class GithubImport
  def self.run!(...)
    new(...).run!
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
    puts "This will import GitHub #{@repo[:full_name].bright} into GitLab #{@project_path.bright} as #{@current_user.name}"
    puts 'Permission checks are ignored. Press any key to continue.'.color(:red)

    $stdin.getch

    puts 'Starting the import (this could take a while)'.color(:green)
  end

  def import!
    @project.import_state.force_start

    timings = Benchmark.measure do
      Gitlab::GithubImport::SequentialImporter
        .new(@project, token: @options[:token])
        .execute
    end

    @project.after_import
    puts "Import finished. Timings: #{timings}".color(:green)
  end

  def new_project
    namespace_path, _sep, project_name = @project_path.rpartition('/')
    target_namespace = Namespace.find_by_full_path(namespace_path)

    raise s_('GithubImport|Namespace or group to import repository into does not exist.') unless target_namespace

    Project.transaction do
      project = Projects::CreateService.new(
        @current_user,
        name: project_name,
        path: project_name,
        description: @repo[:description],
        namespace_id: target_namespace.id,
        visibility_level: visibility_level,
        skip_wiki: @repo[:has_wiki]
      ).execute

      project.update!(
        import_type: 'github',
        import_source: @repo[:full_name],
        import_url: @repo[:clone_url].sub('://', "://#{@options[:token]}@")
      )

      project
    end
  end

  def visibility_level
    @repo[:private] ? Gitlab::VisibilityLevel::PRIVATE : Gitlab::CurrentSettings.current_application_settings.default_project_visibility
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
      print "ID: #{repo[:id].to_s.bright}".color(:green)
      print "\tName: #{repo[:full_name]}\n".color(:green)
    end

    print 'ID? '.bright

    repos.find { |repo| repo[:id] == repo_id }
  end

  def found_github_repo
    repos.find { |repo| repo[:full_name] == @github_repo }
  end

  def repo_id
    @repo_id ||= $stdin.gets.chomp.to_i
  end

  def repos
    @repos ||= @client.repos
  end
end

namespace :import do
  require 'benchmark'
  require 'rainbow/ext/string'

  desc 'GitLab | Import | Import a GitHub project - Example: import:github[ToKeN,root,root/blah,my/github_repo] (optional my/github_repo)'
  task :github, [:token, :gitlab_username, :project_path] => :environment do |_t, args|
    abort 'Project path must be: namespace(s)/project_name'.color(:red) unless args.project_path.include?('/')

    GithubImport.run!(args.token, args.gitlab_username, args.project_path, args.extras)
  end
end
