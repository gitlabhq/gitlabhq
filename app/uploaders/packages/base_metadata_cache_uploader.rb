# frozen_string_literal: true

module Packages
  class BaseMetadataCacheUploader < GitlabUploader
    include ObjectStorage::Concern
    include Packages::GcsSignedUrlMetadata

    storage_location :packages

    alias_method :upload, :model

    def filename
      raise NotImplementedError, 'Metadata cache uploaders must implement filename'
    end

    def store_dir
      dynamic_segment
    end

    private

    def dynamic_segment
      raise ObjectNotReadyError, "#{model.class} model not ready" unless model.object_storage_key

      model.object_storage_key
    end
  end
end
