module ObjectStorable
  extend ActiveSupport::Concern

  included do
    scope :with_files_stored_locally, -> { where(self::STORE_COLUMN => [nil, ObjectStorage::Store::LOCAL]) }
    scope :with_files_stored_remotely, -> { where(self::STORE_COLUMN => ObjectStorage::Store::REMOTE) }
  end
end
