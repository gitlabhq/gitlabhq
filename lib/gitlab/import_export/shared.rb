module Gitlab
  module ImportExport
    class Shared
      attr_reader :errors, :project

      def initialize(project)
        @project = project
        @errors = []
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
        error_out(error.message, caller[0].dup)
        add_error_message(error.message)

        # Debug:
        if error.backtrace
          Rails.logger.error("Import/Export backtrace: #{error.backtrace.join("\n")}")
        else
          Rails.logger.error("No backtrace found")
        end
      end

      def add_error_message(error_message)
        @errors << error_message
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

      def error_out(message, caller)
        Rails.logger.error("Import/Export error raised on #{caller}: #{message}")
      end

      def after_export_lock_file
        AfterExportStrategies::BaseAfterExportStrategy.lock_file_path(project)
      end
    end
  end
end
