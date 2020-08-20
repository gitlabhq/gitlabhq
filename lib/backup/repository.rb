# frozen_string_literal: true

require 'yaml'

module Backup
  class Repository
    attr_reader :progress

    def initialize(progress)
      @progress = progress
    end

    def dump(max_concurrency:, max_storage_concurrency:)
      prepare

      if max_concurrency <= 1 && max_storage_concurrency <= 1
        return dump_consecutive
      end

      if Project.excluding_repository_storage(Gitlab.config.repositories.storages.keys).exists?
        raise Error, 'repositories.storages in gitlab.yml is misconfigured'
      end

      semaphore = Concurrent::Semaphore.new(max_concurrency)
      errors = Queue.new

      threads = Gitlab.config.repositories.storages.keys.map do |storage|
        Thread.new do
          dump_storage(storage, semaphore, max_storage_concurrency: max_storage_concurrency)
        rescue => e
          errors << e
        end
      end

      threads.each(&:join)

      raise errors.pop unless errors.empty?
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
    end

    def restore
      Project.find_each(batch_size: 1000) do |project|
        progress.print " * #{project.full_path} ... "

        restore_repo_success =
          begin
            try_restore_repository(project)
          rescue => err
            progress.puts "Error: #{err}".color(:red)
            false
          end

        if restore_repo_success
          progress.puts "[DONE]".color(:green)
        else
          progress.puts "[Failed] restoring #{project.full_path} repository".color(:red)
        end

        wiki = ProjectWiki.new(project)
        wiki.repository.remove rescue nil
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

      restore_object_pools
    end

    protected

    def try_restore_repository(project)
      path_to_project_bundle = path_to_bundle(project)
      project.repository.remove rescue nil

      if File.exist?(path_to_project_bundle)
        project.repository.create_from_bundle(path_to_project_bundle)
        restore_custom_hooks(project)
      else
        project.repository.create_repository
      end

      true
    end

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

    def dump_consecutive
      Project.find_each(batch_size: 1000) do |project|
        dump_project(project)
      end
    end

    def dump_storage(storage, semaphore, max_storage_concurrency:)
      errors = Queue.new
      queue = SizedQueue.new(1)

      threads = Array.new(max_storage_concurrency) do
        Thread.new do
          while project = queue.pop
            semaphore.acquire

            begin
              dump_project(project)
            rescue => e
              errors << e
              break
            ensure
              semaphore.release
            end
          end
        end
      end

      Project.for_repository_storage(storage).find_each(batch_size: 100) do |project|
        break unless errors.empty?

        queue.push(project)
      end

      queue.close
      threads.each(&:join)

      raise errors.pop unless errors.empty?
    end

    def dump_project(project)
      progress.puts " * #{display_repo_path(project)} ... "

      if project.hashed_storage?(:repository)
        FileUtils.mkdir_p(File.dirname(File.join(backup_repos_path, project.disk_path)))
      else
        FileUtils.mkdir_p(File.join(backup_repos_path, project.namespace.full_path)) if project.namespace
      end

      if !empty_repo?(project)
        backup_project(project)
        progress.puts " * #{display_repo_path(project)} ... " + "[DONE]".color(:green)
      else
        progress.puts " * #{display_repo_path(project)} ... " + "[SKIPPED]".color(:cyan)
      end

      wiki = ProjectWiki.new(project)

      if !empty_repo?(wiki)
        backup_project(wiki)
        progress.puts " * #{display_repo_path(project)} ... " + "[DONE] Wiki".color(:green)
      else
        progress.puts " * #{display_repo_path(project)} ... " + "[SKIPPED] Wiki".color(:cyan)
      end
    end

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

    def restore_object_pools
      PoolRepository.includes(:source_project).find_each do |pool|
        progress.puts " - Object pool #{pool.disk_path}..."

        pool.source_project ||= pool.member_projects.first.root_of_fork_network
        pool.state = 'none'
        pool.save

        pool.schedule
      end
    end
  end
end
