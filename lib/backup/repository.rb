require 'yaml'
require_relative 'helper'

module Backup
  class Repository
    include Backup::Helper

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
      Gitlab.config.repositories.storages.each do |name, repository_storage|
        delete_all_repositories(name, repository_storage)
      end
    end

    def backup_project(project)
      gitaly_migrate(:repository_backup, status: Gitlab::GitalyClient::MigrationStatus::OPT_OUT) do |is_enabled|
        if is_enabled
          backup_project_gitaly(project)
        else
          backup_project_local(project)
        end
      end

      backup_custom_hooks(project)
    rescue => e
      progress_warn(project, e, 'Failed to backup repo')
    end

    def backup_project_gitaly(project)
      path_to_project_bundle = path_to_bundle(project)
      Gitlab::GitalyClient::RepositoryService.new(project.repository)
        .create_bundle(path_to_project_bundle)
    end

    def backup_project_local(project)
      path_to_project_repo = Gitlab::GitalyClient::StorageSettings.allow_disk_access do
        path_to_repo(project)
      end

      path_to_project_bundle = path_to_bundle(project)

      cmd = %W(#{Gitlab.config.git.bin_path} --git-dir=#{path_to_project_repo} bundle create #{path_to_project_bundle} --all)
      output, status = Gitlab::Popen.popen(cmd)
      progress_warn(project, cmd.join(' '), output) unless status.zero?
    end

    def delete_all_repositories(name, repository_storage)
      gitaly_migrate(:delete_all_repositories, status: Gitlab::GitalyClient::MigrationStatus::OPT_OUT) do |is_enabled|
        if is_enabled
          Gitlab::GitalyClient::StorageService.new(name).delete_all_repositories
        else
          local_delete_all_repositories(name, repository_storage)
        end
      end
    end

    def local_delete_all_repositories(name, repository_storage)
      path = repository_storage.legacy_disk_path
      return unless File.exist?(path)

      bk_repos_path = File.join(Gitlab.config.backup.path, "tmp", "#{name}-repositories.old." + Time.now.to_i.to_s)
      FileUtils.mkdir_p(bk_repos_path, mode: 0700)
      files = Dir.glob(File.join(path, "*"), File::FNM_DOTMATCH) - [File.join(path, "."), File.join(path, "..")]

      begin
        FileUtils.mv(files, bk_repos_path)
      rescue Errno::EACCES
        access_denied_error(path)
      rescue Errno::EBUSY
        resource_busy_error(path)
      end
    end

    def local_restore_custom_hooks(project, dir)
      path_to_project_repo = Gitlab::GitalyClient::StorageSettings.allow_disk_access do
        path_to_repo(project)
      end
      cmd = %W(tar -xf #{path_to_tars(project, dir)} -C #{path_to_project_repo} #{dir})
      output, status = Gitlab::Popen.popen(cmd)
      unless status.zero?
        progress_warn(project, cmd.join(' '), output)
      end
    end

    def gitaly_restore_custom_hooks(project, dir)
      custom_hooks_path = path_to_tars(project, dir)
      Gitlab::GitalyClient::RepositoryService.new(project.repository)
        .restore_custom_hooks(custom_hooks_path)
    end

    def local_backup_custom_hooks(project)
      in_path(path_to_tars(project)) do |dir|
        path_to_project_repo = Gitlab::GitalyClient::StorageSettings.allow_disk_access do
          path_to_repo(project)
        end
        break unless File.exist?(File.join(path_to_project_repo, dir))

        FileUtils.mkdir_p(path_to_tars(project))
        cmd = %W(tar -cf #{path_to_tars(project, dir)} -c #{path_to_project_repo} #{dir})
        output, status = Gitlab::Popen.popen(cmd)

        unless status.zero?
          progress_warn(project, cmd.join(' '), output)
        end
      end
    end

    def gitaly_backup_custom_hooks(project)
      FileUtils.mkdir_p(path_to_tars(project))
      custom_hooks_path = path_to_tars(project, 'custom_hooks')
      Gitlab::GitalyClient::RepositoryService.new(project.repository)
        .backup_custom_hooks(custom_hooks_path)
    end

    def backup_custom_hooks(project)
      gitaly_migrate(:backup_custom_hooks, status: Gitlab::GitalyClient::MigrationStatus::OPT_OUT) do |is_enabled|
        if is_enabled
          gitaly_backup_custom_hooks(project)
        else
          local_backup_custom_hooks(project)
        end
      end
    end

    def restore_custom_hooks(project)
      in_path(path_to_tars(project)) do |dir|
        gitaly_migrate(:restore_custom_hooks, status: Gitlab::GitalyClient::MigrationStatus::OPT_OUT) do |is_enabled|
          if is_enabled
            gitaly_restore_custom_hooks(project, dir)
          else
            local_restore_custom_hooks(project, dir)
          end
        end
      end
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
            project.repository.create_from_bundle path_to_project_bundle
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

        restore_custom_hooks(project)

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

    def path_to_repo(project)
      project.repository.path_to_repo
    end

    def path_to_bundle(project)
      File.join(backup_repos_path, project.disk_path + '.bundle')
    end

    def path_to_tars(project, dir = nil)
      path = File.join(backup_repos_path, project.disk_path)

      if dir
        File.join(path, "#{dir}.tar")
      else
        path
      end
    end

    def backup_repos_path
      File.join(Gitlab.config.backup.path, 'repositories')
    end

    def in_path(path)
      return unless Dir.exist?(path)

      dir_entries = Dir.entries(path)

      if dir_entries.include?('custom_hooks') || dir_entries.include?('custom_hooks.tar')
        yield('custom_hooks')
      end
    end

    def prepare
      FileUtils.rm_rf(backup_repos_path)
      FileUtils.mkdir_p(Gitlab.config.backup.path)
      FileUtils.mkdir(backup_repos_path, mode: 0700)
    end

    def silent
      { err: '/dev/null', out: '/dev/null' }
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

    def repository_storage_paths_args
      Gitlab.config.repositories.storages.values.map { |rs| rs.legacy_disk_path }
    end

    def display_repo_path(project)
      project.hashed_storage?(:repository) ? "#{project.full_path} (#{project.disk_path})" : project.full_path
    end

    def gitaly_migrate(method, status: Gitlab::GitalyClient::MigrationStatus::OPT_IN, &block)
      Gitlab::GitalyClient.migrate(method, status: status, &block)
    rescue GRPC::NotFound, GRPC::BadStatus => e
      raise Error, e
    end
  end
end
