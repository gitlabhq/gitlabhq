class GitLabProjectImport
  def self.run(*args)
    new(*args).run
  end

  def initialize(project_path, gitlab_username, file_path)
    @project_path = project_path
    @current_user = User.find_by_username(gitlab_username)
    @file_path = file_path
  end

  def run
    project = import_project

    puts "Project will be exported to #{project.export_path}"
  end

  private

  def done
    @project.errors.invalid? || %w[failed finished].include?(@project.reload.import_status)
  end

  def show_warning!
    puts "This will import GitLab #{@file_path.bright} into GitLab #{@project_path.bright} as #{@current_user.name}"
    puts "Permission checks are ignored. Press any key to continue.".color(:red)

    STDIN.getch

    puts 'Starting the import (this could take a while)'.color(:green)
  end

  def import_project
    Project.transaction do
      namespace_path, _sep, name = @project_path.rpartition('/')
      namespace = find_or_create_namespace(namespace_path)

      ::Projects::GitlabProjectsImportService.new(@current_user, namespace_id: namespace.id, path: name).execute
    end
  end

  def find_or_create_namespace(names)
    return @current_user.namespace if names == @current_user.namespace_path
    return @current_user.namespace unless @current_user.can_create_group?

    Groups::NestedCreateService.new(@current_user, group_path: names).execute
  end
end

namespace :gitlab do
  namespace :import_export do
    desc 'GitLab | Show Import/Export version'
    task version: :environment do
      puts "Import/Export v#{Gitlab::ImportExport.version}"
    end

    desc 'GitLab | Display exported DB structure'
    task data: :environment do
      puts YAML.load_file(Gitlab::ImportExport.config_file)['project_tree'].to_yaml(SortKeys: true)
    end

    desc 'GitLab | Import a project'
    task :import, [:project_path, :gitlab_username, :file_path] => :environment do |_t, args|
      GitLabProjectImport.new(args.project_path, args.gitlab_username, args.file_path)
    end

    desc 'GitLab | Export a project'
    task :export, [:project_path, :gitlab_username] => :environment do |_t, args|
      project = Project.find_by_full_path(args.project_path)
      project.add_export_job(current_user: User.find_by_username(args.gitlab_username))

      puts "Project #{project.name} will be exported."
    end

    desc 'GitLab | Check the Import/Export status of a project'
    task :status, [:project_path, :gitlab_username] => :environment do |_t, args|
      project = Project.find_by_full_path(args.project_path)

      puts "Project exported to #{project.export_project_path}" if project.export_project_path

      puts case project.import_status
             when 'finished', 'scheduled', 'started'
               "Project import #{project.import_status}."
             when 'failed'
               "Project import failed with error: #{project.import_error}"
           end
    end
  end
end
