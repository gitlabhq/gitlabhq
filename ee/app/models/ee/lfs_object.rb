module EE
  # LFS Object EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `LfsObject` model
  module LfsObject
    extend ActiveSupport::Concern

    prepended do
      after_destroy :log_geo_deleted_event

      scope :geo_syncable, -> { with_files_stored_locally }
      scope :with_files_stored_remotely, -> { where(file_store: LfsObjectUploader::Store::REMOTE) }
    end

    def log_geo_deleted_event
      ::Geo::LfsObjectDeletedEventStore.new(self).create!
    end
  end
end
