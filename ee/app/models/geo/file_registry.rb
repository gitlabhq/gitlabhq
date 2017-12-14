class Geo::FileRegistry < Geo::BaseRegistry
  scope :failed, -> { where(success: false) }
  scope :synced, -> { where(success: true) }
  scope :retry_due, -> { where('retry_at is NULL OR retry_at < ?', Time.now) }
  scope :lfs_objects, -> { where(file_type: :lfs) }
  scope :attachments, -> { where(file_type: Geo::FileService::DEFAULT_OBJECT_TYPES) }
end
