module EE
  # LFS Object EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `LfsObject` model
  module LfsObject
    extend ActiveSupport::Concern

    prepended do
      include ObjectStorage::BackgroundMove

      after_destroy :log_geo_event

      scope :with_files_stored_locally, -> { where(file_store: [nil, LfsObjectUploader::Store::LOCAL]) }
      scope :with_files_stored_remotely, -> { where(file_store: ObjectStorage::Store::REMOTE) }
    end

    def local_store?
      [nil, LfsObjectUploader::Store::LOCAL].include?(self.file_store)
    end

    private

    def log_geo_event
      ::Geo::LfsObjectDeletedEventStore.new(self).create
    end
  end
end
