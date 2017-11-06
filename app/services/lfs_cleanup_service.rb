class LfsCleanupService
  attr_reader :project

  MIN_LFS_USAGE = 5.megabytes

  def initialize(project)
    @project = project
  end

  def execute
    return unless project.lfs_enabled?
    return unless project.lfs_pointers.exists?
    return if project.unprocessed_lfs_pushes.exists?
    return unless project.lfs_objects.exists?
    return if project.statistics.lfs_objects_size < MIN_LFS_USAGE

    delete_unreferenced_pointers!

    project.lfs_objects_projects.without_pointers.delete_all

    ProjectCacheWorker.perform_async(project.id, [], [:lfs_objects_size])
  end

  def delete_unreferenced_pointers!
    unreferenced_pointers.delete_all
  end

  private

  def unreferenced_pointers
    project.lfs_pointers.where(blob_oid: removed_pointer_oids)
  end

  def removed_pointer_oids
    @removed_pointer_oids ||= begin
      pointer_oids = project.lfs_pointers.pluck(:blob_oid)
      project.repository.batch_existence(pointer_oids, existing: false)
    end
  end
end
