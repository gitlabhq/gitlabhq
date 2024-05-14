# frozen_string_literal: true

module Packages
  module Npm
    class MetadataCacheUploader < GitlabUploader
      include ObjectStorage::Concern
      include Packages::GcsSignedUrlMetadata

      FILENAME = 'metadata.json'

      storage_location :packages

      alias_method :upload, :model

      def filename
        FILENAME
      end

      def store_dir
        dynamic_segment
      end

      private

      def dynamic_segment
        raise ObjectNotReadyError, 'Packages::Npm::MetadataCache model not ready' unless model.object_storage_key

        model.object_storage_key
      end
    end
  end
end
