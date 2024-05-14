# frozen_string_literal: true

module Packages
  module Nuget
    class SymbolUploader < GitlabUploader
      include ObjectStorage::Concern
      include Packages::GcsSignedUrlMetadata

      storage_location :packages

      alias_method :upload, :model

      def store_dir
        dynamic_segment
      end

      private

      def dynamic_segment
        raise ObjectNotReadyError, 'Packages::Nuget::Symbol model not ready' unless model.object_storage_key

        model.object_storage_key
      end
    end
  end
end
