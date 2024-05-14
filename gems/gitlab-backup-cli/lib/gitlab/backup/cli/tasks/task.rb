# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Tasks
        class Task
          attr_reader :options, :context

          # Identifier used as parameter in the CLI to skip from executing
          def self.id
            raise NotImplementedError
          end

          def initialize(context:, options:)
            @context = context
            @options = options
          end

          # Initiate a backup
          #
          # @param [Pathname] backup_path a path where to store the backups
          # @param [String] backup_id
          def backup!(backup_path, backup_id)
            backup_output = backup_path.join(destination_path)

            # During test, we ensure storage exists so we can run against `RAILS_ENV=test` environment
            FileUtils.mkdir_p(storage_path) if context.env.test? && respond_to?(:storage_path, true)

            target.dump(backup_output, backup_id)
          end

          def restore!(archive_directory)
            archived_data_location = Pathname(archive_directory).join(destination_path)

            target.restore(archived_data_location, nil)
          end

          # Key string that identifies the task
          def id = self.class.id

          # Name of the task used for logging.
          def human_name
            raise NotImplementedError
          end

          # Where the task should put its backup file/dir
          def destination_path
            raise NotImplementedError
          end

          # Path to remove after a successful backup, uses #destination_path when not specified
          def cleanup_path
            destination_path
          end

          # `true` if the destination might not exist on a successful backup
          def destination_optional
            false
          end

          # `true` if the task can be used
          def enabled
            true
          end

          def enabled?
            enabled
          end

          private

          # The target factory method
          def target
            raise NotImplementedError
          end
        end
      end
    end
  end
end
