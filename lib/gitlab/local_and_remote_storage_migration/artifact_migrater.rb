# frozen_string_literal: true

module Gitlab
  module LocalAndRemoteStorageMigration
    class ArtifactMigrater < Gitlab::LocalAndRemoteStorageMigration::BaseMigrater
      def migrate_to_local_storage
        logger.info('Starting transfer to local storage')
        migrate(items_with_files_stored_remotely, ObjectStorage::Store::LOCAL) do |artifact|
          FilePathFixer.fix_file_path!(artifact)
          artifact.update_column(:file_final_path, nil) if artifact.file_final_path.present?
        end
      end

      private

      def items_with_files_stored_locally
        ::Ci::JobArtifact.with_files_stored_locally
      end

      def items_with_files_stored_remotely
        ::Ci::JobArtifact.with_files_stored_remotely
      end
    end
  end
end
