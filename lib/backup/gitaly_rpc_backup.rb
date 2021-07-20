# frozen_string_literal: true

module Backup
  # Backup and restores repositories using the gitaly RPC
  class GitalyRpcBackup
    def initialize(progress)
      @progress = progress
    end

    def start(type)
      raise Error, 'already started' if @type

      @type = type
      case type
      when :create
        FileUtils.rm_rf(backup_repos_path)
        FileUtils.mkdir_p(Gitlab.config.backup.path)
        FileUtils.mkdir(backup_repos_path, mode: 0700)
      when :restore
        # no op
      else
        raise Error, "unknown backup type: #{type}"
      end
    end

    def wait
      @type = nil
    end

    def enqueue(container, repository_type)
      backup_restore = BackupRestore.new(
        progress,
        repository_type.repository_for(container),
        backup_repos_path
      )

      case @type
      when :create
        backup_restore.backup
      when :restore
        backup_restore.restore(always_create: repository_type.project?)
      else
        raise Error, 'not started'
      end
    end

    def parallel_enqueue?
      true
    end

    private

    attr_reader :progress

    def backup_repos_path
      @backup_repos_path ||= File.join(Gitlab.config.backup.path, 'repositories')
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
          progress.puts " * #{display_repo_path} ... " + "[EMPTY] [SKIPPED]".color(:cyan)
          return
        end

        FileUtils.mkdir_p(repository_backup_path)

        repository.bundle_to_disk(path_to_bundle)
        repository.gitaly_repository_client.backup_custom_hooks(custom_hooks_tar)

        progress.puts " * #{display_repo_path} ... " + "[DONE]".color(:green)

      rescue StandardError => e
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

      rescue StandardError => e
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
  end
end
