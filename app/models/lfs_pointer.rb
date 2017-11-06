class LfsPointer < ActiveRecord::Base
  include EachBatch

  belongs_to :project

  validates :project, presence: true
  validates :blob_oid, presence: true
  validates :lfs_oid, presence: true

  # Finds pointers which exist only in the database
  # This is a slow method and should be called in batches
  def self.missing_on_disk(repository)
    oids = pluck(:blob_oid)
    removed_oids = repository.batch_existence(oids, existing: false)
    where(blob_oid: removed_oids)
  end
end
