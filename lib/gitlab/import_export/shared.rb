# frozen_string_literal: true

module Gitlab
  module ImportExport
    class Shared
      attr_reader :errors, :project

      def initialize(project)
        @project = project
        @errors = []
        @logger = Gitlab::Import::Logger.build
      end

      def active_export_count
        Dir[File.join(archive_path, '*')].count { |name| File.directory?(name) }
      end

      def export_path
        @export_path ||= Gitlab::ImportExport.export_path(relative_path: relative_path)
      end

      def archive_path
        @archive_path ||= Gitlab::ImportExport.export_path(relative_path: relative_archive_path)
      end

      def error(error)
        log_error(message: error.message, caller: caller[0].dup)
        log_debug(backtrace: error.backtrace&.join("\n"))

        Gitlab::Sentry.track_acceptable_exception(error, extra: log_base_data)

        add_error_message(error.message)
      end

      def add_error_message(message)
        @errors << filtered_error_message(message)
      end

      def after_export_in_progress?
        File.exist?(after_export_lock_file)
      end

      private

      def relative_path
        File.join(relative_archive_path, SecureRandom.hex)
      end

      def relative_archive_path
        @project.disk_path
      end

      def log_error(details)
        @logger.error(log_base_data.merge(details))
      end

      def log_debug(details)
        @logger.debug(log_base_data.merge(details))
      end

      def log_base_data
        {
          importer: 'Import/Export',
          import_jid: @project&.import_state&.jid,
          project_id: @project&.id,
          project_path: @project&.full_path
        }
      end

      def filtered_error_message(message)
        Projects::ImportErrorFilter.filter_message(message)
      end

      def after_export_lock_file
        AfterExportStrategies::BaseAfterExportStrategy.lock_file_path(project)
      end
    end
  end
end
