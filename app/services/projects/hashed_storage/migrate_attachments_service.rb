module Projects
  module HashedStorage
    class MigrateAttachmentsService < BaseService
      attr_reader :logger

      BATCH_SIZE = 500

      def initialize(project, logger = nil)
        @project = project
        @logger = logger || Rails.logger
      end

      def execute
        project_before_migration = project.dup
        project.storage_version = ::Project::HASHED_STORAGE_FEATURES[:attachments]

        project.uploads.find_each(batch_size: BATCH_SIZE) do |upload|
          old_path = attachments_path(project_before_migration, upload)
          new_path = attachments_path(project, upload)
          move_attachment(old_path, new_path)
        end

        project.save!
      end

      private

      def attachments_path(project, upload)
        File.join(
          FileUploader.dynamic_path_segment(project),
          upload.path
        )
      end

      def move_attachment(old_path, new_path)
        unless File.file?(old_path)
          logger.error("Failed to migrate attachment from '#{old_path}' to '#{new_path}', source file doesn't exist (PROJECT_ID=#{project.id})")
          return
        end

        # Create attachments folder if doesn't exist yet
        FileUtils.mkdir_p(File.dirname(new_path)) unless Dir.exist?(File.dirname(new_path))

        if File.file?(new_path)
          logger.info("Skipped attachment migration from '#{old_path}' to '#{new_path}', target file already exist (PROJECT_ID=#{project.id})")
          return
        end

        FileUtils.mv(old_path, new_path)
        logger.info("Migrated project attachment from '#{old_path}' to '#{new_path}' (PROJECT_ID=#{project.id})")
      end
    end
  end
end
