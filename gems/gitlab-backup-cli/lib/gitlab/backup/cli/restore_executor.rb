# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      # This is responsible for executing a Restore operation
      #
      # A Restore Executor handles the creation and deletion of
      # temporary environment necessary for a restoration to happen
      #
      class RestoreExecutor < BaseExecutor
        attr_reader :context, :backup_id, :workdir, :archive_directory

        # @param [Context::SourceContext|Context::OmnibusContext] context
        # @param [String] backup_id
        def initialize(
          context:,
          backup_id: nil,
          backup_bucket: nil,
          wait_for_completion: nil,
          registry_bucket: nil,
          service_account_file: nil
        )
          @context = context
          @backup_id = backup_id
          @workdir = create_temporary_workdir!
          @archive_directory = context.backup_basedir.join(backup_id)

          @metadata = nil
          super(
            backup_bucket: backup_bucket,
            wait_for_completion: wait_for_completion,
            registry_bucket: registry_bucket,
            service_account_file: service_account_file
          )
        end

        def execute
          read_metadata!

          execute_all_tasks
        end

        def metadata
          @metadata ||= read_metadata!
        end

        # At the end of a successful restore, call this to release temporary resources
        def release!
          FileUtils.rm_rf(workdir)
        end

        private

        def execute_all_tasks
          tasks = []
          Gitlab::Backup::Cli::Tasks.build_each(context: context) do |task|
            # This is a temporary hack while we move away from options and use config instead
            # This hack will be removed as part of https://gitlab.com/gitlab-org/gitlab/-/issues/498455
            task.set_registry_bucket(registry_bucket) if task.is_a?(Gitlab::Backup::Cli::Tasks::Registry)

            Gitlab::Backup::Cli::Output.info("Executing restoration of #{task.human_name}...")

            duration = measure_duration do
              tasks << { name: task.human_name, result: task.restore!(archive_directory) }
            end

            next if task.object_storage?

            Gitlab::Backup::Cli::Output.success("Finished restoration of #{task.human_name}! (#{duration.in_seconds}s)")
          end

          if wait_for_completion
            tasks.each do |task|
              next unless task[:result].respond_to?(:wait_until_done)

              wait_for_task(task[:result])
            end
          else
            Gitlab::Backup::Cli::Output.info("Restore tasks complete! Not waiting for object storage tasks to complete")
          end
        end

        def read_metadata!
          @metadata = Gitlab::Backup::Cli::Metadata::BackupMetadata.load!(archive_directory)
        end

        # @return [Pathname] temporary directory
        def create_temporary_workdir!
          # Ensure base directory exists
          # KYLE - does this need to exist? Maybe for tests?
          FileUtils.mkdir_p(context.backup_basedir)

          Pathname(Dir.mktmpdir('restore', context.backup_basedir))
        end

        def measure_duration
          start = Time.now
          yield

          ActiveSupport::Duration.build(Time.now - start)
        end

        def wait_for_task(task)
          Gitlab::Backup::Cli::Output.info("Waiting for Restore of #{task.name} to finish...")

          r = task.wait_until_done!
          if r.error?
            Gitlab::Backup::Cli::Output.error("Restore of #{task.name} failed!")
          else
            Gitlab::Backup::Cli::Output.success("Finished Restore of #{task.name}!")
          end
        end
      end
    end
  end
end
