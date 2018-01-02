module Geo
  class RenameRepositoryWorker
    include ApplicationWorker
    include GeoQueue

    def perform(project_id, old_disk_path, new_disk_path)
      Geo::RenameRepositoryService.new(project_id, old_disk_path, new_disk_path).execute
    end
  end
end
