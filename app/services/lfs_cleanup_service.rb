class LfsCleanupService
  attr_reader :project

  def initialize(project)
    @project = project
  end

  def remove_unreferenced
    return unless project.lfs_enabled?
    return unless project.lfs_pointers.exists? # LFS pointers were found
    return unless project.reference_changes.exists? # Has been scanned for lfs pointers
    return if project.reference_changes.unprocessed.exists? # No scans still in progress
    return unless project.lfs_objects.exists?

    unreferenced_pointers.destroy_all
  end

  def unreferenced_pointers
    pointer_oids = project.lfs_pointers.pluck(:blob_oid)
    removed_pointer_oids = Gitlab::Git::Blob.batch_blob_existance(project.repository,
                                                                  pointer_oids,
                                                                  existing: false)

    project.lfs_pointers.where(blob_oid: removed_pointer_oids)
  end
end
