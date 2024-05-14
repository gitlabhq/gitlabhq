# frozen_string_literal: true

module Backup
  module Restore
    class Process
      attr_reader :backup_id, :backup_task, :backup_path, :logger

      # Restore process class, dedicated to perform restore tasks
      #
      # @param [String] backup_id Current or previous backup ID
      # @param [Backup::Tasks::Task] backup_task Task to restore
      # @param [Pathname] backup_path Pathname of the backup
      # @param [Gitlab::BackupLogger] logger interface
      def initialize(backup_id:, backup_task:, backup_path:, logger:)
        @backup_id = backup_id
        @backup_task = backup_task
        @backup_path = backup_path
        @logger = logger
      end

      def execute!
        return unless backup_task_enabled?

        logger.info "Restoring #{backup_task.human_name} ... "

        # Pre restore
        output_warning(backup_task.pre_restore_warning)

        # Restore
        backup_task.restore!(backup_path, backup_id)

        logger.info "Restoring #{backup_task.human_name} ... done"

        # Post restore
        output_warning(backup_task.post_restore_warning)
      rescue Gitlab::TaskAbortedByUserError
        logger.error "Quitting..."

        exit 1
      end

      private

      def backup_task_enabled?
        return true if backup_task.enabled?

        logger.info "Restoring #{backup_task.human_name} ... [DISABLED]"
        false
      end

      def output_warning(warning)
        return unless warning.present?

        logger.warn warning
        Gitlab::TaskHelpers.ask_to_continue
      end
    end
  end
end
