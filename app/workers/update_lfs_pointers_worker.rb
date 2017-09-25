class UpdateLfsPointersWorker
  include Sidekiq::Worker
  include CronjobQueue

  attr_reader :reference_change

  def perform(reference_change_id)
    @reference_change = ReferenceChange.find(reference_change_id)

    return unless project.lfs_enabled?
    return if @reference_change.processed?

    create_lfs_pointer_records

    reference_change.update!(processed: true)
  end

  private

  def create_lfs_pointer_records
    new_lfs_pointers.each do |blob|
      project.lfs_pointers.create!(blob_oid: blob.id, lfs_oid: blob.lfs_oid)
    end
  end

  def new_lfs_pointers
    processed_references = project.reference_changes.processed.pluck(:newrev)

    lfs_changes = Gitlab::Git::LfsChanges.new(project.repository, reference_change.newrev)
    lfs_changes.new_pointers(not_in: processed_references)
  end

  def project
    reference_change.project
  end
end
