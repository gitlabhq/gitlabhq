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
    project.lfs_pointers.each_batch do |lfs_pointers_batch|
      lfs_pointers_batch.missing_on_disk(project.repository).delete_all
    end
  end
end
