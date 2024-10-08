# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Commands
        class RestoreSubcommand < ObjectStorageCommand
          package_name 'Restore'

          desc 'all BACKUP_ID', 'Restores a backup including repositories, database and local files'
          def all(backup_id)
            Gitlab::Backup::Cli.update_process_title!("restore all from #{backup_id}")

            duration = measure_duration do
              Gitlab::Backup::Cli::Output.info("Initializing environment...")
              Gitlab::Backup::Cli.rails_environment!
            end
            Gitlab::Backup::Cli::Output.success("Environment loaded. (#{duration.in_seconds}s)")

            restore_executor =
              Gitlab::Backup::Cli::RestoreExecutor.new(
                context: build_context,
                backup_id: backup_id,
                backup_bucket: options["backup_bucket"],
                wait_for_completion: options["wait_for_completion"],
                registry_bucket: options["registry_bucket"],
                service_account_file: options["service_account_file"]
              )

            duration = measure_duration do
              Gitlab::Backup::Cli::Output.info("Restoring GitLab backup #{backup_id}... (#{restore_executor.workdir})")

              restore_executor.execute

              restore_executor.release!
            end
            Gitlab::Backup::Cli::Output.success(
              "GitLab restoration of backup #{backup_id} finished (#{duration.in_seconds}s)"
            )
          rescue Gitlab::Backup::Cli::Error => e
            Gitlab::Backup::Cli::Output.error("GitLab Backup failed: #{e.message} (#{restore_executor.workdir})")

            exit 1
          end

          private

          def build_context
            Gitlab::Backup::Cli::Context.build
          end

          def measure_duration
            start = Time.now
            yield

            ActiveSupport::Duration.build(Time.now - start)
          end
        end
      end
    end
  end
end
