module Geo
  class RenameRepositoryService
    attr_reader :project_id, :old_disk_path, :new_disk_path

    def initialize(project_id, old_disk_path, new_disk_path)
      @project_id = project_id
      @old_disk_path = old_disk_path
      @new_disk_path = new_disk_path
    end

    def async_execute
      Geo::RenameRepositoryWorker.perform_async(project_id, old_disk_path, new_disk_path)
    end

    def execute
      project.expire_caches_before_rename(old_disk_path)

      if project.legacy_storage? && !move_repository
        raise RepositoryCannotBeRenamed, "Repository #{old_disk_path} could not be renamed to #{new_disk_path}"
      end

      true
    end

    private

    def project
      @project ||= Project.find(project_id)
    end

    def move_repository
      Geo::MoveRepositoryService.new(project, old_disk_path, new_disk_path).execute
    end
  end
end
