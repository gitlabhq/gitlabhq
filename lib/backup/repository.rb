require 'yaml'

module Backup
  class Repository
    attr_reader :progress

    def initialize(progress)
      @progress = progress
    end

    def dump
      prepare

      Project.find_each(batch_size: 1000) do |project|
        progress.print " * #{display_repo_path(project)} ... "

        if project.hashed_storage?(:repository)
          FileUtils.mkdir_p(File.dirname(File.join(backup_repos_path, project.disk_path)))
        else
          FileUtils.mkdir_p(File.join(backup_repos_path, project.namespace.full_path)) if project.namespace
        end

        if !empty_repo?(project)
          backup_project(project)
          progress.puts "[DONE]".color(:green)
        else
          progress.puts "[SKIPPED]".color(:cyan)
        end

        wiki = ProjectWiki.new(project)

        if !empty_repo?(wiki)
          backup_project(wiki)
          progress.puts "[DONE] Wiki".color(:green)
        else
          progress.puts "[SKIPPED] Wiki".color(:cyan)
        end
      end
    end

    def prepare_directories
      Gitlab.config.repositories.storages.each do |name, _repository_storage|
        Gitlab::GitalyClient::StorageService.new(name).delete_all_repositories
      end
    end

    def backup_project(project)
      path_to_project_bundle = path_to_bundle(project)
      Gitlab::GitalyClient::RepositoryService.new(project.repository)
        .create_bundle(path_to_project_bundle)

      backup_custom_hooks(project)
    rescue => e
      progress_warn(project, e, 'Failed to backup repo')
    end

    def backup_custom_hooks(project)
      FileUtils.mkdir_p(project_backup_path(project))

      custom_hooks_path = custom_hooks_tar(project)
      Gitlab::GitalyClient::RepositoryService.new(project.repository)
        .backup_custom_hooks(custom_hooks_path)
    end

    def restore_custom_hooks(project)
      return unless Dir.exist?(project_backup_path(project))
      return if Dir.glob("#{project_backup_path(project)}/custom_hooks*").none?

      custom_hooks_path = custom_hooks_tar(project)
      Gitlab::GitalyClient::RepositoryService.new(project.repository)
        .restore_custom_hooks(custom_hooks_path)
#    rescue => e
#      progress_warn(project, e, 'Failed to restore custom hooks')
    end

    def restore
      prepare_directories
      gitlab_shell = Gitlab::Shell.new

      Project.find_each(batch_size: 1000) do |project|
        progress.print " * #{project.full_path} ... "
        path_to_project_bundle = path_to_bundle(project)
        project.ensure_storage_path_exists

        restore_repo_success = nil
        if File.exist?(path_to_project_bundle)
          begin
            project.repository.create_from_bundle(path_to_project_bundle)
puts 'created from bundle'
            restore_custom_hooks(project)
            restore_repo_success = true
          rescue => e
            restore_repo_success = false
            progress.puts "Error: #{e}".color(:red)
          end
        else
          restore_repo_success = gitlab_shell.create_repository(project.repository_storage, project.disk_path)
        end

        if restore_repo_success
          progress.puts "[DONE]".color(:green)
        else
          progress.puts "[Failed] restoring #{project.full_path} repository".color(:red)
        end

        wiki = ProjectWiki.new(project)
        path_to_wiki_bundle = path_to_bundle(wiki)

        if File.exist?(path_to_wiki_bundle)
          progress.print " * #{wiki.full_path} ... "
          begin
            wiki.repository.create_from_bundle(path_to_wiki_bundle)
            restore_custom_hooks(wiki)

            progress.puts "[DONE]".color(:green)
          rescue => e
            progress.puts "[Failed] restoring #{wiki.full_path} wiki".color(:red)
            progress.puts "Error #{e}".color(:red)
          end
        end
      end
    end

    protected

    def path_to_bundle(project)
      File.join(backup_repos_path, project.disk_path + '.bundle')
    end

    def project_backup_path(project)
      File.join(backup_repos_path, project.disk_path)
    end

    def custom_hooks_tar(project)
      File.join(project_backup_path(project), "custom_hooks.tar")
    end

    def backup_repos_path
      File.join(Gitlab.config.backup.path, 'repositories')
    end

    def prepare
      FileUtils.rm_rf(backup_repos_path)
      FileUtils.mkdir_p(Gitlab.config.backup.path)
      FileUtils.mkdir(backup_repos_path, mode: 0700)
    end

    private

    def progress_warn(project, cmd, output)
      progress.puts "[WARNING] Executing #{cmd}".color(:orange)
      progress.puts "Ignoring error on #{display_repo_path(project)} - #{output}".color(:orange)
    end

    def empty_repo?(project_or_wiki)
      project_or_wiki.repository.expire_emptiness_caches
      project_or_wiki.repository.empty?
    end

    def display_repo_path(project)
      project.hashed_storage?(:repository) ? "#{project.full_path} (#{project.disk_path})" : project.full_path
    end
  end
end
