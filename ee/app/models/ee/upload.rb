module EE
  # Upload EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `Upload` model
  module Upload
    extend ActiveSupport::Concern

    prepended do
      after_destroy :log_geo_event

      scope :geo_syncable, -> { with_files_stored_locally }
    end

    private

    def log_geo_event
      ::Geo::UploadDeletedEventStore.new(self).create
    end
  end
end
