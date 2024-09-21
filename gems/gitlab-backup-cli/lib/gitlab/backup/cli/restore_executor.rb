# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      # This is responsible for executing a Restore operation
      #
      # A Restore Executor handles the creation and deletion of
      # temporary environment necessary for a restoration to happen
      #
      class RestoreExecutor
        attr_reader :context, :backup_id, :workdir, :archive_directory

        # @param [Context::SourceContext|Context::OmnibusContext] context
        # @param [String] backup_id
        def initialize(context:, backup_id:)
          @context = context
          @backup_id = backup_id
          @workdir = create_temporary_workdir!
          @archive_directory = context.backup_basedir.join(backup_id)

          @metadata = nil
          @backup_options = nil
        end

        def execute
          read_metadata!

          execute_all_tasks
        end

        def backup_options
          @backup_options ||= build_backup_options!
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
          # TODO: when we migrate targets to the new codebase, recreate options to have only what we need here
          # https://gitlab.com/gitlab-org/gitlab/-/issues/454906
          Gitlab::Backup::Cli::Tasks.build_each(context: context, options: backup_options) do |task|
            Gitlab::Backup::Cli::Output.info("Executing restoration of #{task.human_name}...")

            duration = measure_duration do
              task.restore!(archive_directory)
            end

            Gitlab::Backup::Cli::Output.success("Finished restoration of #{task.human_name}! (#{duration.in_seconds}s)")
          end
        end

        def read_metadata!
          @metadata = Gitlab::Backup::Cli::Metadata::BackupMetadata.load!(archive_directory)
        end

        def build_backup_options!
          ::Backup::Options.new(
            backup_id: backup_id
          )
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
      end
    end
  end
end
