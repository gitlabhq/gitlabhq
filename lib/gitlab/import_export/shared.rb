# frozen_string_literal: true
#
# This class encapsulates the directories used by project import/export:
#
# 1. The project export job first generates the project metadata tree
#    (e.g. `project.json) and repository bundle (e.g. `project.bundle`)
#    inside a temporary `export_path`
#    (e.g. /path/to/shared/tmp/project_exports/namespace/project/:randomA/:randomB).
#
# 2. The job then creates a tarball (e.g. `project.tar.gz`) in
#    `archive_path` (e.g. /path/to/shared/tmp/project_exports/namespace/project/:randomA).
#    CarrierWave moves this tarball files into its permanent location.
#
# 3. Lock files are used to indicate whether a project is in the
#    `after_export` state.  These are stored in a directory
#    (e.g. /path/to/shared/tmp/project_exports/namespace/project/locks. The
#    number of lock files present signifies how many concurrent project
#    exports are running. Note that this assumes the temporary directory
#    is a shared mount:
#    https://gitlab.com/gitlab-org/gitlab/issues/32203
#
# NOTE: Stale files should be cleaned up via ImportExportCleanupService.
module Gitlab
  module ImportExport
    class Shared
      attr_reader :errors, :exportable, :logger

      LOCKS_DIRECTORY = 'locks'

      def initialize(exportable)
        @exportable = exportable
        @errors     = []
        @logger     = ::Import::Framework::Logger.build
      end

      def active_export_count
        Dir[File.join(base_path, '*')].count { |name| File.basename(name) != LOCKS_DIRECTORY && File.directory?(name) }
      end

      # The path where the exportable metadata and repository bundle (in case of project) is saved
      def export_path
        @export_path ||= Gitlab::ImportExport.export_path(relative_path: relative_path)
      end

      # The path where the tarball is saved
      def archive_path
        @archive_path ||= Gitlab::ImportExport.export_path(relative_path: relative_archive_path)
      end

      def base_path
        @base_path ||= Gitlab::ImportExport.export_path(relative_path: relative_base_path)
      end

      def lock_files_path
        @locks_files_path ||= File.join(base_path, LOCKS_DIRECTORY)
      end

      def error(error)
        Gitlab::ErrorTracking.track_exception(error, log_base_data)

        add_error_message(error.message)
      end

      def add_error_message(message)
        @errors << filtered_error_message(message)
      end

      def after_export_in_progress?
        locks_present?
      end

      def locks_present?
        Dir.exist?(lock_files_path) && !Dir.empty?(lock_files_path)
      end

      private

      def relative_path
        @relative_path ||= File.join(relative_archive_path, SecureRandom.hex)
      end

      def relative_archive_path
        @relative_archive_path ||= File.join(relative_base_path, SecureRandom.hex)
      end

      def relative_base_path
        case exportable_type
        when 'Project'
          @exportable.disk_path
        when 'Group'
          Storage::Hashed.new(@exportable, prefix: Storage::Hashed::GROUP_REPOSITORY_PATH_PREFIX).disk_path
        else
          raise Gitlab::ImportExport::Error, "Unsupported Exportable Type #{@exportable&.class}"
        end
      end

      def log_base_data
        log = { importer: 'Import/Export' }
        log.merge!(Gitlab::ImportExport::LogUtil.exportable_to_log_payload(@exportable))
        log[:import_jid] = @exportable&.import_state&.jid if exportable_type == 'Project'
        log
      end

      def filtered_error_message(message)
        Projects::ImportErrorFilter.filter_message(message)
      end

      def exportable_type
        @exportable.class.name
      end
    end
  end
end
