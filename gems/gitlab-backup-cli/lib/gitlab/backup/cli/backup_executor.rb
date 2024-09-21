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
      class BackupExecutor
        attr_reader :context, :metadata, :workdir, :archive_directory, :backup_bucket, :wait_for_completion,
          :registry_bucket, :service_account_file

        # @param [Context::SourceContext, Context::OmnibusContext] context
        def initialize(context:, backup_options: {})
          @context = context
          @metadata = build_metadata
          @workdir = create_temporary_workdir!
          @archive_directory = context.backup_basedir.join(metadata.backup_id)
          @backup_bucket = backup_options["backup_bucket"]
          @registry_bucket = backup_options["registry_bucket"]
          @wait_for_completion = backup_options["wait_for_completion"]
          @service_account_file = backup_options["service_account_file"]
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
          # TODO: when we migrate targets to the new codebase, recreate options to have only what we need here
          # https://gitlab.com/gitlab-org/gitlab/-/issues/454906
          options = ::Backup::Options.new(
            remote_directory: backup_bucket,
            container_registry_bucket: registry_bucket,
            service_account_file: service_account_file
          )
          tasks = []

          Gitlab::Backup::Cli::Tasks.build_each(context: context, options: options) do |task|
            Gitlab::Backup::Cli::Output.info("Executing Backup of #{task.human_name}...")

            duration = measure_duration do
              tasks << { name: task.human_name, result: task.backup!(workdir, metadata.backup_id) }
            end

            next unless task.object_storage?

            Gitlab::Backup::Cli::Output.success("Finished Backup of #{task.human_name}! (#{duration.in_seconds}s)")
          end

          if wait_for_completion
            tasks.each do |task|
              next unless task[:result].respond_to?(:wait_until_done!)

              wait_for_task(task[:result])
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
          Gitlab::Backup::Cli::Output.info("Waiting for Backup of #{task.name} to finish...")

          r = task.wait_until_done!
          if r.error?
            Gitlab::Backup::Cli::Output.error("Backup of #{task.name} failed!")
          else
            Gitlab::Backup::Cli::Output.success("Finished Backup of #{task.name}!")
          end
        end
      end
    end
  end
end
