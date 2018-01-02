module Geo
  AttachmentMigrationError = Class.new(StandardError)

  class HashedStorageAttachmentsMigrationService
    include ::Gitlab::Geo::LogHelpers

    attr_reader :project_id, :old_attachments_path, :new_attachments_path

    def initialize(project_id, old_attachments_path:, new_attachments_path:)
      @project_id = project_id
      @old_attachments_path = old_attachments_path
      @new_attachments_path = new_attachments_path
    end

    def async_execute
      Geo::HashedStorageAttachmentsMigrationWorker.perform_async(
        project_id,
        old_attachments_path,
        new_attachments_path
      )
    end

    def execute
      origin = File.join(CarrierWave.root, FileUploader.base_dir, old_attachments_path)
      target = File.join(CarrierWave.root, FileUploader.base_dir, new_attachments_path)
      move_folder!(origin, target)
    end

    private

    def project
      @project ||= Project.find(project_id)
    end

    def move_folder!(old_path, new_path)
      unless File.directory?(old_path)
        log_info("Skipped attachments migration to Hashed Storage, source path doesn't exist or is not a directory", project_id: project.id, source: old_path, target: new_path)
        return
      end

      if File.exist?(new_path)
        log_error("Cannot migrate attachments to Hashed Storage, target path already exist", project_id: project.id, source: old_path, target: new_path)
        raise AttachmentMigrationError, "Target path '#{new_path}' already exist"
      end

      # Create hashed storage base path folder
      FileUtils.mkdir_p(File.dirname(new_path))

      FileUtils.mv(old_path, new_path)
      log_info("Migrated project attachments to Hashed Storage", project_id: project.id, source: old_path, target: new_path)

      true
    end
  end
end
