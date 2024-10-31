# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      # This is responsible for executing a Backup operation
      #
      # A Backup Executor handles the creation and deletion of
      # temporary environment necessary for a backup to happen
      #
      # It also allows for multiple backups to happen in parallel
      # without one overwriting data from another
      class BackupExecutor < BaseExecutor
        attr_reader :context, :metadata, :workdir, :archive_directory

        # @param [Gitlab::Backup::Cli::SourceContext, Context::OmnibusContext] context
        def initialize(
          context:,
          backup_bucket: nil,
          wait_for_completion: nil,
          registry_bucket: nil,
          service_account_file: nil)
          @context = context
          @metadata = build_metadata
          @workdir = create_temporary_workdir!
          @archive_directory = context.backup_basedir.join(metadata.backup_id)
          super(
            backup_bucket: backup_bucket,
            wait_for_completion: wait_for_completion,
            registry_bucket: registry_bucket,
            service_account_file: service_account_file
          )
        end

        def execute
          execute_all_tasks

          write_metadata!
          archive!
        end

        # At the end of a successful backup, call this to release temporary resources
        def release!
          FileUtils.rm_rf(workdir)
        end

        private

        def build_metadata
          @metadata = Gitlab::Backup::Cli::Metadata::BackupMetadata.build(gitlab_version: context.gitlab_version)
        end

        def execute_all_tasks
          tasks = []

          Gitlab::Backup::Cli::Tasks.build_each(context: context) do |task|
            # This is a temporary hack while we move away from options and use config instead
            # This hack will be removed as part of https://gitlab.com/gitlab-org/gitlab/-/issues/498455
            task.set_registry_bucket(registry_bucket) if task.is_a?(Gitlab::Backup::Cli::Tasks::Registry)

            Gitlab::Backup::Cli::Output.info("Executing Backup of #{task.human_name}...")

            duration = measure_duration do
              task.backup!(workdir)
              tasks << task
            end

            next if task.asynchronous?

            Gitlab::Backup::Cli::Output.success("Finished Backup of #{task.human_name}! (#{duration.in_seconds}s)")
          end

          if wait_for_completion
            tasks.each do |task|
              wait_for_task(task)
            end
          else
            Gitlab::Backup::Cli::Output.info('Backup tasks completed! Not waiting for object storage tasks to complete')
          end
        end

        # Write the backup_information.json data to disk
        def write_metadata!
          return if metadata.write!(workdir)

          raise Gitlab::Backup::Cli::Error, 'Failed to write metadata to disk'
        end

        def archive!
          # TODO: create a single-file archive instead of moving everything to a directory
          # https://gitlab.com/gitlab-org/gitlab/-/issues/454832
          FileUtils.mkdir(archive_directory)
          workdir.glob('*').each { |entry| FileUtils.mv(entry, archive_directory) }
        end

        # @return [Pathname] temporary directory
        def create_temporary_workdir!
          # Ensure base directory exists
          FileUtils.mkdir_p(context.backup_basedir)

          Pathname(Dir.mktmpdir('backup', context.backup_basedir))
        end

        def measure_duration
          start = Time.now
          yield

          ActiveSupport::Duration.build(Time.now - start)
        end

        def wait_for_task(task)
          return unless task.asynchronous?

          Gitlab::Backup::Cli::Output.info("Waiting for Backup of #{task.human_name} to finish...")

          r = task.wait_until_done!
          if r.error?
            Gitlab::Backup::Cli::Output.error("Backup of #{task.human_name} failed!")
          else
            Gitlab::Backup::Cli::Output.success("Finished Backup of #{task.human_name}!")
          end
        end
      end
    end
  end
end
