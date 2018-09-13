module Geo
  class FilesExpireService
    include ::Gitlab::Geo::LogHelpers

    BATCH_SIZE = 500

    attr_reader :project, :old_full_path

    def initialize(project, old_full_path)
      @project = project
      @old_full_path = old_full_path
    end

    # Expire already replicated uploads
    #
    # This is a fallback solution to support projects that haven't rolled out to hashed-storage yet.
    #
    # Note: Unless we add some locking mechanism, this will be best effort only
    # as if there are files that are being replicated during this execution, they will not
    # be expired.
    #
    # The long-term solution is to use hashed storage.
    def execute
      return unless Gitlab::Geo.secondary?

      uploads = finder.find_project_uploads(project)
      log_info("Expiring replicated attachments after project rename", count: uploads.count)

      schedule_file_removal(uploads)
      mark_for_resync!
    end

    # Project's base directory for attachments storage
    #
    # @return base directory where all uploads for the project are stored
    def base_dir
      @base_dir ||= File.join(FileUploader.root, old_full_path)
    end

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def schedule_file_removal(uploads)
      paths_to_remove = uploads.find_each(batch_size: BATCH_SIZE).each_with_object([]) do |upload, to_remove|
        file_path = File.join(base_dir, upload.path)

        if File.exist?(file_path)
          to_remove << [file_path]

          log_info("Scheduled to remove file", file_path: file_path)
        end
      end

      Geo::FileRemovalWorker.bulk_perform_async(paths_to_remove)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def mark_for_resync!
      finder.find_file_registries_uploads(project).delete_all
    end

    def finder
      @finder ||= ::Geo::ExpireUploadsFinder.new
    end

    # This is called by LogHelpers to build json log with context info
    #
    # @see ::Gitlab::Geo::LogHelpers
    def base_log_data(message)
      {
        class: self.class.name,
        project_id: project.id,
        project_path: project.full_path,
        project_old_path: old_full_path,
        message: message
      }
    end
  end
end
