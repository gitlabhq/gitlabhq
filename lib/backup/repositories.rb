# frozen_string_literal: true

require 'yaml'

module Backup
  class Repositories
    attr_reader :progress

    def initialize(progress)
      @progress = progress
    end

    def dump(max_concurrency:, max_storage_concurrency:)
      prepare

      if max_concurrency <= 1 && max_storage_concurrency <= 1
        return dump_consecutive
      end

      check_valid_storages!

      semaphore = Concurrent::Semaphore.new(max_concurrency)
      errors = Queue.new

      threads = Gitlab.config.repositories.storages.keys.map do |storage|
        Thread.new do
          Rails.application.executor.wrap do
            dump_storage(storage, semaphore, max_storage_concurrency: max_storage_concurrency)
          rescue => e
            errors << e
          end
        end
      end

      ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
        threads.each(&:join)
      end

      raise errors.pop unless errors.empty?
    end

    def restore
      Project.find_each(batch_size: 1000) do |project|
        restore_repository(project, Gitlab::GlRepository::PROJECT)
        restore_repository(project, Gitlab::GlRepository::WIKI)
        restore_repository(project, Gitlab::GlRepository::DESIGN)
      end

      invalid_ids = Snippet.find_each(batch_size: 1000)
        .map { |snippet| restore_snippet_repository(snippet) }
        .compact

      cleanup_snippets_without_repositories(invalid_ids)

      restore_object_pools
    end

    private

    def check_valid_storages!
      [ProjectRepository, SnippetRepository].each do |klass|
        if klass.excluding_repository_storage(Gitlab.config.repositories.storages.keys).exists?
          raise Error, "repositories.storages in gitlab.yml does not include all storages used by #{klass}"
        end
      end
    end

    def backup_repos_path
      @backup_repos_path ||= File.join(Gitlab.config.backup.path, 'repositories')
    end

    def prepare
      FileUtils.rm_rf(backup_repos_path)
      FileUtils.mkdir_p(Gitlab.config.backup.path)
      FileUtils.mkdir(backup_repos_path, mode: 0700)
    end

    def dump_consecutive
      dump_consecutive_projects
      dump_consecutive_snippets
    end

    def dump_consecutive_projects
      project_relation.find_each(batch_size: 1000) do |project|
        dump_project(project)
      end
    end

    def dump_consecutive_snippets
      Snippet.find_each(batch_size: 1000) { |snippet| dump_snippet(snippet) }
    end

    def dump_storage(storage, semaphore, max_storage_concurrency:)
      errors = Queue.new
      queue = InterlockSizedQueue.new(1)

      threads = Array.new(max_storage_concurrency) do
        Thread.new do
          Rails.application.executor.wrap do
            while container = queue.pop
              ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
                semaphore.acquire
              end

              begin
                case container
                when Project
                  dump_project(container)
                when Snippet
                  dump_snippet(container)
                end
              rescue => e
                errors << e
                break
              ensure
                semaphore.release
              end
            end
          end
        end
      end

      enqueue_records_for_storage(storage, queue, errors)

      raise errors.pop unless errors.empty?
    ensure
      queue.close
      ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
        threads.each(&:join)
      end
    end

    def dump_project(project)
      backup_repository(project, Gitlab::GlRepository::PROJECT)
      backup_repository(project, Gitlab::GlRepository::WIKI)
      backup_repository(project, Gitlab::GlRepository::DESIGN)
    end

    def dump_snippet(snippet)
      backup_repository(snippet, Gitlab::GlRepository::SNIPPET)
    end

    def enqueue_records_for_storage(storage, queue, errors)
      records_to_enqueue(storage).each do |relation|
        relation.find_each(batch_size: 100) do |project|
          break unless errors.empty?

          queue.push(project)
        end
      end
    end

    def records_to_enqueue(storage)
      [projects_in_storage(storage), snippets_in_storage(storage)]
    end

    def projects_in_storage(storage)
      project_relation.id_in(ProjectRepository.for_repository_storage(storage).select(:project_id))
    end

    def project_relation
      Project.includes(:route, :group, namespace: :owner)
    end

    def snippets_in_storage(storage)
      Snippet.id_in(SnippetRepository.for_repository_storage(storage).select(:snippet_id))
    end

    def backup_repository(container, type)
      BackupRestore.new(
        progress,
        type.repository_for(container),
        backup_repos_path
      ).backup
    end

    def restore_repository(container, type)
      BackupRestore.new(
        progress,
        type.repository_for(container),
        backup_repos_path
      ).restore(always_create: type.project?)
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

    def restore_snippet_repository(snippet)
      restore_repository(snippet, Gitlab::GlRepository::SNIPPET)

      response = Snippets::RepositoryValidationService.new(nil, snippet).execute

      if response.error?
        snippet.repository.remove

        progress.puts("Snippet #{snippet.full_path} can't be restored: #{response.message}")

        snippet.id
      else
        nil
      end
    end

    # Snippets without a repository should be removed because they failed to import
    # due to having invalid repositories
    def cleanup_snippets_without_repositories(ids)
      Snippet.id_in(ids).delete_all
    end

    class BackupRestore
      attr_accessor :progress, :repository, :backup_repos_path

      def initialize(progress, repository, backup_repos_path)
        @progress = progress
        @repository = repository
        @backup_repos_path = backup_repos_path
      end

      def backup
        progress.puts " * #{display_repo_path} ... "

        if repository.empty?
          progress.puts " * #{display_repo_path} ... " + "[SKIPPED]".color(:cyan)
          return
        end

        FileUtils.mkdir_p(repository_backup_path)

        repository.bundle_to_disk(path_to_bundle)
        repository.gitaly_repository_client.backup_custom_hooks(custom_hooks_tar)

        progress.puts " * #{display_repo_path} ... " + "[DONE]".color(:green)

      rescue => e
        progress.puts "[Failed] backing up #{display_repo_path}".color(:red)
        progress.puts "Error #{e}".color(:red)
      end

      def restore(always_create: false)
        progress.puts " * #{display_repo_path} ... "

        repository.remove rescue nil

        if File.exist?(path_to_bundle)
          repository.create_from_bundle(path_to_bundle)
          restore_custom_hooks
        elsif always_create
          repository.create_repository
        end

        progress.puts " * #{display_repo_path} ... " + "[DONE]".color(:green)

      rescue => e
        progress.puts "[Failed] restoring #{display_repo_path}".color(:red)
        progress.puts "Error #{e}".color(:red)
      end

      private

      def display_repo_path
        "#{repository.full_path} (#{repository.disk_path})"
      end

      def repository_backup_path
        @repository_backup_path ||= File.join(backup_repos_path, repository.disk_path)
      end

      def path_to_bundle
        @path_to_bundle ||= File.join(backup_repos_path, repository.disk_path + '.bundle')
      end

      def restore_custom_hooks
        return unless File.exist?(custom_hooks_tar)

        repository.gitaly_repository_client.restore_custom_hooks(custom_hooks_tar)
      end

      def custom_hooks_tar
        File.join(repository_backup_path, "custom_hooks.tar")
      end
    end

    class InterlockSizedQueue < SizedQueue
      extend ::Gitlab::Utils::Override

      override :pop
      def pop(*)
        ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
          super
        end
      end

      override :push
      def push(*)
        ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
          super
        end
      end
    end
  end
end
