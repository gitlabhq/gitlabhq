# frozen_string_literal: true

module Gitlab
  module LocalAndRemoteStorageMigration
    class ArtifactMigrater < Gitlab::LocalAndRemoteStorageMigration::BaseMigrater
      def migrate_to_remote_storage
        logger.info('Starting transfer to object storage')
        migrate(::Ci::JobArtifact.with_files_stored_locally, ObjectStorage::Store::REMOTE)
        migrate(::Ci::PipelineArtifact.with_files_stored_locally, ObjectStorage::Store::REMOTE)
      end

      def migrate_to_local_storage
        logger.info('Starting transfer to local storage')
        migrate(::Ci::JobArtifact.with_files_stored_remotely, ObjectStorage::Store::LOCAL) do |artifact|
          FilePathFixer.fix_file_path!(artifact)
          artifact.update_column(:file_final_path, nil) if artifact.file_final_path.present?
        end
        migrate(::Ci::PipelineArtifact.with_files_stored_remotely, ObjectStorage::Store::LOCAL)
      end
    end
  end
end
