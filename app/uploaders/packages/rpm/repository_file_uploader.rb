# frozen_string_literal: true
module Packages
  module Rpm
    class RepositoryFileUploader < GitlabUploader
      include ObjectStorage::Concern
      include Packages::GcsSignedUrlMetadata

      storage_location :packages

      alias_method :upload, :model

      def filename
        model.file_name
      end

      def store_dir
        dynamic_segment
      end

      private

      def dynamic_segment
        raise ObjectNotReadyError, 'Repository file model not ready' unless model.id

        Gitlab::HashedPath.new(
          'projects', model.project_id, 'rpm', 'repository_files', model.id,
          root_hash: model.project_id
        )
      end
    end
  end
end
