# frozen_string_literal: true

module Backup
  # Backup and restores repositories using gitaly-backup
  class GitalyBackup
    def initialize(progress, parallel: nil)
      @progress = progress
      @parallel = parallel
    end

    def start(type)
      raise Error, 'already started' if started?

      command = case type
                when :create
                  'create'
                when :restore
                  'restore'
                else
                  raise Error, "unknown backup type: #{type}"
                end

      args = []
      args += ['-parallel', @parallel.to_s] if type == :create && @parallel

      @read_io, @write_io = IO.pipe
      @pid = Process.spawn(bin_path, command, '-path', backup_repos_path, *args, in: @read_io, out: @progress)
    end

    def wait
      return unless started?

      @write_io.close
      Process.wait(@pid)
      status = $?

      @pid = nil

      raise Error, "gitaly-backup exit status #{status.exitstatus}" if status.exitstatus != 0
    end

    def enqueue(container, repo_type)
      raise Error, 'not started' unless started?

      repository = repo_type.repository_for(container)

      @write_io.puts({
        storage_name: repository.storage,
        relative_path: repository.relative_path,
        gl_project_path: repository.gl_project_path,
        always_create: repo_type.project?
      }.merge(Gitlab::GitalyClient.connection_data(repository.storage)).to_json)
    end

    def parallel_enqueue?
      false
    end

    private

    def started?
      @pid.present?
    end

    def backup_repos_path
      File.absolute_path(File.join(Gitlab.config.backup.path, 'repositories'))
    end

    def bin_path
      File.absolute_path(Gitlab.config.backup.gitaly_backup_path)
    end
  end
end
