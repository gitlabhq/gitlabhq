module Geo
  class HashedStorageMigrationService
    attr_reader :project_id, :old_disk_path, :new_disk_path

    def initialize(project_id, old_disk_path, new_disk_path)
      @project_id = project_id
      @old_disk_path = old_disk_path
      @new_disk_path = new_disk_path
    end

    def async_execute
      Geo::HashedStorageMigrationWorker.perform_async(project_id, old_disk_path, new_disk_path)
    end

    def execute
      project = Project.find(project_id)
      project.expire_caches_before_rename(old_disk_path)

      Geo::MoveRepositoryService.new(project, old_disk_path, new_disk_path).execute
    end
  end
end
