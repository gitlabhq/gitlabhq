# frozen_string_literal: true

module Backup
  # Backup and restores repositories using gitaly-backup
  #
  # gitaly-backup can work in parallel and accepts a list of repositories
  # through input pipe using a specific json format for both backup and restore
  class GitalyBackup
    # @param [StringIO] progress IO interface to output progress
    # @param [Integer] max_parallelism max parallelism when running backups
    # @param [Integer] storage_parallelism max parallelism per storage (is affected by max_parallelism)
    def initialize(progress, max_parallelism: nil, storage_parallelism: nil, incremental: false, backup_id: nil)
      @progress = progress
      @max_parallelism = max_parallelism
      @storage_parallelism = storage_parallelism
      @incremental = incremental
    end

    def start(type, backup_repos_path, backup_id: nil)
      raise Error, 'already started' if started?

      if type == :create && !incremental?
        FileUtils.rm_rf(backup_repos_path)
      end

      command = case type
                when :create
                  'create'
                when :restore
                  'restore'
                else
                  raise Error, "unknown backup type: #{type}"
                end

      args = []
      args += ['-parallel', @max_parallelism.to_s] if @max_parallelism
      args += ['-parallel-storage', @storage_parallelism.to_s] if @storage_parallelism
      if Feature.enabled?(:incremental_repository_backup)
        args += ['-layout', 'pointer']
        if type == :create
          args += ['-incremental'] if incremental?
          args += ['-id', backup_id] if backup_id
        end
      end

      @input_stream, stdout, @thread = Open3.popen2(build_env, bin_path, command, '-path', backup_repos_path, *args)

      @out_reader = Thread.new do
        IO.copy_stream(stdout, @progress)
      end
    end

    def finish!
      return unless started?

      @input_stream.close
      [@thread, @out_reader].each(&:join)
      status =  @thread.value

      @thread = nil

      raise Error, "gitaly-backup exit status #{status.exitstatus}" if status.exitstatus != 0
    end

    def enqueue(container, repo_type)
      raise Error, 'not started' unless started?

      repository = repo_type.repository_for(container)

      schedule_backup_job(repository, always_create: repo_type.project?)
    end

    private

    def incremental?
      @incremental
    end

    # Schedule a new backup job through a non-blocking JSON based pipe protocol
    #
    # @see https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/gitaly-backup.md
    def schedule_backup_job(repository, always_create:)
      connection_params = Gitlab::GitalyClient.connection_data(repository.storage)

      json_job = {
        address: connection_params['address'],
        token: connection_params['token'],
        storage_name: repository.storage,
        relative_path: repository.relative_path,
        gl_project_path: repository.gl_project_path,
        always_create: always_create
      }.to_json

      @input_stream.puts(json_job)
    end

    def build_env
      {
        'SSL_CERT_FILE' => OpenSSL::X509::DEFAULT_CERT_FILE,
        'SSL_CERT_DIR'  => OpenSSL::X509::DEFAULT_CERT_DIR
      }.merge(ENV)
    end

    def started?
      @thread.present?
    end

    def bin_path
      raise Error, 'gitaly-backup binary not found and gitaly_backup_path is not configured' unless Gitlab.config.backup.gitaly_backup_path.present?

      File.absolute_path(Gitlab.config.backup.gitaly_backup_path)
    end
  end
end
