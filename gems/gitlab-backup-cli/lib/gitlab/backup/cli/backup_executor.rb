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
        attr_reader :context, :metadata, :workdir, :archive_directory

        # @param [Gitlab::Backup::Cli::SourceContext] context
        def initialize(context:)
          @context = context
          @metadata = build_metadata
          @workdir = create_temporary_workdir!
          @archive_directory = context.backup_basedir.join(metadata.backup_id)
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
          options = ::Backup::Options.new

          Gitlab::Backup::Cli::Tasks.build_each(context: context, options: options) do |task|
            Gitlab::Backup::Cli::Output.info("Executing Backup of #{task.human_name}...")

            duration = measure_duration do
              task.backup!(workdir, metadata.backup_id)
            end

            Gitlab::Backup::Cli::Output.success("Finished Backup of #{task.human_name}! (#{duration.in_seconds}s)")
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
      end
    end
  end
end
