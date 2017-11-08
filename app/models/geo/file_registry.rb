class Geo::FileRegistry < Geo::BaseRegistry
  scope :failed, -> { where(success: false) }
  scope :synced, -> { where(success: true) }
  scope :lfs_objects, -> { where(file_type: :lfs) }
  scope :attachments, -> { where(file_type: Geo::FileService::DEFAULT_OBJECT_TYPES) }
end
