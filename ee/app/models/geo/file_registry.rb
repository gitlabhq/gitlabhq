class Geo::FileRegistry < Geo::BaseRegistry
  include Geo::Syncable

  scope :lfs_objects, -> { where(file_type: :lfs) }
  scope :attachments, -> { where(file_type: Geo::FileService::DEFAULT_OBJECT_TYPES) }
end
