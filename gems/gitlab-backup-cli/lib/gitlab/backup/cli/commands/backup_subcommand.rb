# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Commands
        class BackupSubcommand < Command
          package_name 'Backup'

          EXECUTOR_OPTIONS = %w[backup_bucket wait_for_completion registry_bucket service_account_file].freeze

          class_option :backup_bucket,
            desc: "When backing up object storage, this is the bucket to backup to",
            required: false

          class_option :wait_for_completion,
            desc: "Wait for object storage backups to complete",
            type: :boolean,
            default: true

          class_option :registry_bucket,
            desc: "When backing up registry from object storage, this is the source bucket",
            required: false

          class_option :service_account_file,
            desc: "JSON file containing the Google service account credentials",
            default: "/etc/gitlab/backup-account-credentials.json"

          desc 'all', 'Creates a backup including repositories, database and local files'
          def all
            duration = measure_duration do
              Gitlab::Backup::Cli::Output.info("Initializing environment...")
              Gitlab::Backup::Cli.rails_environment!
            end
            Gitlab::Backup::Cli::Output.success("Environment loaded. (#{duration.in_seconds}s)")

            backup_executor = Gitlab::Backup::Cli::BackupExecutor.new(
              context: build_context, backup_options: executor_options
            )
            backup_id = backup_executor.metadata.backup_id

            duration = measure_duration do
              Gitlab::Backup::Cli::Output.info("Starting GitLab backup... (#{backup_executor.workdir})")

              backup_executor.execute

              backup_executor.release!
            end
            Gitlab::Backup::Cli::Output.success("GitLab Backup finished: #{backup_id} (#{duration.in_seconds}s)")
          rescue Gitlab::Backup::Cli::Error => e
            Gitlab::Backup::Cli::Output.error("GitLab Backup failed: #{e.message} (#{backup_executor.workdir})")

            exit 1
          end

          private

          def build_context
            ::Gitlab::Backup::Cli::Context.build
          end

          def measure_duration
            start = Time.now
            yield

            ActiveSupport::Duration.build(Time.now - start)
          end

          def executor_options
            options.select { |key, _| EXECUTOR_OPTIONS.include?(key) }
          end
        end
      end
    end
  end
end
