class UpdateLfsPointersWorker
  include Sidekiq::Worker
  include CronjobQueue

  attr_reader :unprocessed_lfs_push

  def perform(unprocessed_lfs_push_id)
    @unprocessed_lfs_push = UnprocessedLfsPush.find(unprocessed_lfs_push_id)

    return unless project.lfs_enabled?

    create_lfs_pointer_records

    unprocessed_lfs_push.processed!
  end

  private

  def create_lfs_pointer_records
    new_lfs_pointers.each do |blob|
      project.lfs_pointers.create!(blob_oid: blob.id, lfs_oid: blob.lfs_oid)
    end
  end

  def new_lfs_pointers
    processed_references = project.processed_lfs_refs
                                  .order(updated_at: :desc)
                                  .limit(100)
                                  .pluck(:ref)

    lfs_changes = Gitlab::Git::LfsChanges.new(project.repository, unprocessed_lfs_push.newrev)

    if processed_references.present?
      lfs_changes.new_pointers(not_in: processed_references)
    else
      lfs_changes.all_pointers
    end
  end

  def project
    unprocessed_lfs_push.project
  end
end
