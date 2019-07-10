# frozen_string_literal: true

module Projects
  module HashedStorage
    class MigrateAttachmentsService < BaseAttachmentService
      def initialize(project, old_disk_path, logger: nil)
        @project = project
        @logger = logger || Rails.logger # rubocop:disable Gitlab/RailsLogger
        @old_disk_path = old_disk_path
        @skipped = false
      end

      def execute
        origin = FileUploader.absolute_base_dir(project)
        # It's possible that old_disk_path does not match project.disk_path.
        # For example, that happens when we rename a project
        origin.sub!(/#{Regexp.escape(project.full_path)}\z/, old_disk_path)

        project.storage_version = ::Project::HASHED_STORAGE_FEATURES[:attachments]
        target = FileUploader.absolute_base_dir(project)

        @new_disk_path = project.disk_path

        result = move_folder!(origin, target)

        if result
          project.save!(validate: false)

          yield if block_given?
        else
          # Rollback changes
          project.rollback!
        end

        result
      end
    end
  end
end
