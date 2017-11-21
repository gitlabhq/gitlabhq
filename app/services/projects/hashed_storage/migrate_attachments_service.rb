module Projects
  module HashedStorage
    AttachmentMigrationError = Class.new(StandardError)

    class MigrateAttachmentsService < BaseService
      attr_reader :logger

      def initialize(project, logger = nil)
        @project = project
        @logger = logger || Rails.logger
      end

      def execute
        old_path = FileUploader.dynamic_path_segment(project)
        project.storage_version = ::Project::HASHED_STORAGE_FEATURES[:attachments]
        new_path = FileUploader.dynamic_path_segment(project)

        move_folder!(old_path, new_path)
        project.save!
      end

      private

      def move_folder!(old_path, new_path)
        unless File.directory?(old_path)
          logger.info("Skipped attachments migration from '#{old_path}' to '#{new_path}', source path doesn't exist or is not a directory (PROJECT_ID=#{project.id})")
          return
        end

        if File.exist?(new_path)
          logger.error("Cannot migrate attachments from '#{old_path}' to '#{new_path}', target path already exist (PROJECT_ID=#{project.id})")
          raise AttachmentMigrationError, "Target path '#{new_path}' already exist"
        end

        # Create hashed storage base path folder
        FileUtils.mkdir_p(File.expand_path('..', new_path))

        FileUtils.mv(old_path, new_path)
        logger.info("Migrated project attachments from '#{old_path}' to '#{new_path}' (PROJECT_ID=#{project.id})")
      end
    end
  end
end
