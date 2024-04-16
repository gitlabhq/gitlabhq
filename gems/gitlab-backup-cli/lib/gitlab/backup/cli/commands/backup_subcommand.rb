# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Commands
        class BackupSubcommand < Command
          package_name 'Backup'

          desc 'all', 'Creates a backup including repositories, database and local files'
          def all
            duration = measure_duration do
              Gitlab::Backup::Cli::Output.info("Initializing environment...")
              Gitlab::Backup::Cli.rails_environment!
            end
            Gitlab::Backup::Cli::Output.success("Environment loaded. (#{duration.in_seconds}s)")

            backup_executor = Gitlab::Backup::Cli::BackupExecutor.new(context: build_context)
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
            # TODO: When we have more then one context we need to auto-detect which one to use
            # https://gitlab.com/gitlab-org/gitlab/-/issues/454530
            Gitlab::Backup::Cli::SourceContext.new
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
