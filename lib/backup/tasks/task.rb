# frozen_string_literal: true

module Backup
  module Tasks
    class Task
      attr_reader :progress, :options

      # Identifier used as parameter in the CLI to skip from executing
      def self.id
        raise NotImplementedError
      end

      def initialize(progress:, options:)
        @progress = progress
        @options = options
      end

      # Initiate a backup
      #
      # @param [Pathname] backup_path a path where to store the backups
      # @param [String] backup_id
      def backup!(backup_path, backup_id)
        backup_output = backup_path.join(destination_path)

        target.dump(backup_output, backup_id)
      end

      def restore!(backup_path, backup_id)
        backup_output = backup_path.join(destination_path)

        target.restore(backup_output, backup_id)
      end

      # Key string that identifies the task
      def id = self.class.id

      # Name of the task used for logging.
      def human_name
        raise NotImplementedError
      end

      # Where to put the backup content
      # It can be either an archive file or a directory containing multiple data
      def destination_path
        raise NotImplementedError
      end

      # Path to remove after a successful backup, uses #destination_path when not specified
      def cleanup_path = destination_path

      # `true` if the destination might not exist on a successful backup
      def destination_optional = false

      # `true` if the task can be used
      def enabled = true

      def enabled? = enabled

      # a string returned here will be displayed to the user before calling #restore
      def pre_restore_warning = nil

      # a string returned here will be displayed to the user after calling #restore
      def post_restore_warning = nil

      private

      # The target factory method
      def target
        raise NotImplementedError
      end
    end
  end
end
