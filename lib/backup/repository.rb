require 'yaml'
require_relative 'helper'

module Backup
  class Repository
    include Backup::Helper
    # rubocop:disable Metrics/AbcSize

    attr_reader :progress

    def initialize(progress)
      @progress = progress
    end

    def dump
      prepare

      Project.find_each(batch_size: 1000) do |project|
        progress.print " * #{display_repo_path(project)} ... "

        path_to_project_repo = Gitlab::GitalyClient::StorageSettings.allow_disk_access do
          path_to_repo(project)
        end
        path_to_project_bundle = path_to_bundle(project)

        # Create namespace dir or hashed path if missing
        if project.hashed_storage?(:repository)
          FileUtils.mkdir_p(File.dirname(File.join(backup_repos_path, project.disk_path)))
        else
          FileUtils.mkdir_p(File.join(backup_repos_path, project.namespace.full_path)) if project.namespace
        end

        if empty_repo?(project)
          progress.puts "[SKIPPED]".color(:cyan)
        else
          in_path(path_to_project_repo) do |dir|
            FileUtils.mkdir_p(path_to_tars(project))
            cmd = %W(tar -cf #{path_to_tars(project, dir)} -C #{path_to_project_repo} #{dir})
            output, status = Gitlab::Popen.popen(cmd)

            unless status.zero?
              progress_warn(project, cmd.join(' '), output)
            end
          end

          cmd = %W(#{Gitlab.config.git.bin_path} --git-dir=#{path_to_project_repo} bundle create #{path_to_project_bundle} --all)
          output, status = Gitlab::Popen.popen(cmd)

          if status.zero?
            progress.puts "[DONE]".color(:green)
          else
            progress_warn(project, cmd.join(' '), output)
          end
        end

        wiki = ProjectWiki.new(project)
        path_to_wiki_repo = Gitlab::GitalyClient::StorageSettings.allow_disk_access do
          path_to_repo(wiki)
        end
        path_to_wiki_bundle = path_to_bundle(wiki)

        if File.exist?(path_to_wiki_repo)
          progress.print " * #{display_repo_path(wiki)} ... "

          if empty_repo?(wiki)
            progress.puts " [SKIPPED]".color(:cyan)
          else
            cmd = %W(#{Gitlab.config.git.bin_path} --git-dir=#{path_to_wiki_repo} bundle create #{path_to_wiki_bundle} --all)
            output, status = Gitlab::Popen.popen(cmd)
            if status.zero?
              progress.puts " [DONE]".color(:green)
            else
              progress_warn(wiki, cmd.join(' '), output)
            end
          end
        end
      end
    end

    def prepare_directories
      Gitlab.config.repositories.storages.each do |name, repository_storage|
        delete_all_repositories(name, repository_storage)
      end
    end

    def delete_all_repositories(name, repository_storage)
      gitaly_migrate(:delete_all_repositories) do |is_enabled|
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

      # Move all files in the existing repos directory except . and .. to
      # repositories.old.<timestamp> directory
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

    def restore_custom_hooks(project)
      # TODO: Need to find a way to do this for gitaly
      # Gitaly migration issue: https://gitlab.com/gitlab-org/gitaly/issues/1195
      in_path(path_to_tars(project)) do |dir|
        path_to_project_repo = Gitlab::GitalyClient::StorageSettings.allow_disk_access do
          path_to_repo(project)
        end
        cmd = %W(tar -xf #{path_to_tars(project, dir)} -C #{path_to_project_repo} #{dir})

        output, status = Gitlab::Popen.popen(cmd)
        unless status.zero?
          progress_warn(project, cmd.join(' '), output)
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
            progress.puts "[DONE]".color(:green)
          rescue => e
            progress.puts "[Failed] restoring #{wiki.full_path} wiki".color(:red)
            progress.puts "Error #{e}".color(:red)
          end
        end
      end
    end
    # rubocop:enable Metrics/AbcSize

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
      # Ensure the parent dir of backup_repos_path exists
      FileUtils.mkdir_p(Gitlab.config.backup.path)
      # Fail if somebody raced to create backup_repos_path before us
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
      # Protect against stale caches
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
