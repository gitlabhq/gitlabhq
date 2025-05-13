# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Services
        class GitalyBackup
          # Backup and restores repositories using gitaly-backup
          #
          # gitaly-backup can work in parallel and accepts a list of repositories
          # through input pipe using a specific json format for both backup and restore
          attr_reader :context

          def initialize(context)
            @context = context
          end

          def start(type, backup_repos_path, backup_id: nil, remove_all_repositories: nil)
            raise Gitlab::Backup::Cli::Errors::GitalyBackupError, 'already started' if started?

            FileUtils.rm_rf(backup_repos_path) if type == :create

            @input_stream, stdout, @thread = Open3.popen2(
              build_env,
              bin_path,
              *gitaly_backup_args(type, backup_repos_path.to_s, backup_id, remove_all_repositories)
            )

            @out_reader = Thread.new do
              IO.copy_stream(stdout, $stdout)
            end
          end

          def finish!
            return unless started?

            @input_stream.close
            @thread.join
            status =  @thread.value

            @thread = nil

            return unless status.exitstatus != 0

            raise Gitlab::Backup::Cli::Errors::GitalyBackupError,
              "gitaly-backup exit status #{status.exitstatus}"
          end

          def enqueue(container, always_create: false)
            raise Gitlab::Backup::Cli::Errors::GitalyBackupError, 'not started' unless started?

            container_methods = [:disk_path, :storage, :path_with_namespace]
            unless container_methods.all? { |method| container.respond_to?(method) }
              raise Gitlab::Backup::Cli::Errors::GitalyBackupError, 'not a valid container'
            end

            storage = container.repository_storage
            relative_path = container.disk_path
            gl_project_path = container.path_with_namespace

            schedule_backup_job(storage, relative_path, gl_project_path, always_create)
          end

          private

          def gitaly_backup_args(type, backup_repos_path, backup_id, remove_all_repositories)
            command = case type
                      when :create
                        'create'
                      when :restore
                        'restore'
                      else
                        raise Gitlab::Backup::Cli::Errors::GitalyBackupError, "unknown backup type: #{type}"
                      end

            args = [command] + ['-path', backup_repos_path, '-layout', 'manifest']

            case type
            when :create
              args += ['-id', backup_id] if backup_id
            when :restore
              args += ['-remove-all-repositories', remove_all_repositories.join(',')] if remove_all_repositories
              args += ['-id', backup_id] if backup_id
            end

            args
          end

          # Schedule a new backup job through a non-blocking JSON based pipe protocol
          #
          # @see https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/gitaly-backup.md
          def schedule_backup_job(storage, relative_path, gl_project_path, always_create)
            json_job = {
              storage_name: storage,
              relative_path: relative_path,
              gl_project_path: gl_project_path,
              always_create: always_create
            }.to_json

            @input_stream.puts(json_job)
          end

          def gitaly_servers
            storages = context.config_repositories_storages
            unless storages.keys
              raise Gitlab::Backup::Cli::Errors::GitalyBackupError,
                "No repositories' storages found."
            end

            storages.keys.index_with do |storage_name|
              GitalyClient.new(storages, context.gitaly_token).connection_data(storage_name)
            end
          end

          def gitaly_servers_encoded
            Base64.strict_encode64(JSON.dump(gitaly_servers))
          end

          # These variables will be moved to a config file via
          # https://gitlab.com/gitlab-org/gitlab/-/issues/500437
          def default_cert_dir
            ENV.fetch('SSL_CERT_DIR', OpenSSL::X509::DEFAULT_CERT_DIR)
          end

          def default_cert_file
            ENV.fetch('SSL_CERT_FILE', OpenSSL::X509::DEFAULT_CERT_FILE)
          end

          def build_env
            {
              'SSL_CERT_FILE' => default_cert_file,
              'SSL_CERT_DIR' => default_cert_dir,
              'GITALY_SERVERS' => gitaly_servers_encoded
            }.merge(current_env)
          end

          def current_env
            ENV
          end

          def started?
            @thread.present?
          end

          def bin_path
            unless context.gitaly_backup_path.present?
              raise Gitlab::Backup::Cli::Errors::GitalyBackupError,
                'gitaly-backup binary not found and gitaly_backup_path is not configured'
            end

            File.absolute_path(context.gitaly_backup_path)
          end
        end
      end
    end
  end
end
