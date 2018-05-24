# frozen_string_literal: true
# rubocop:disable Metrics/AbcSize
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class MigrateLegacyArtifacts
      class Build < ActiveRecord::Base
        self.table_name = 'ci_builds'
        self.inheritance_column = :_type_disabled

        scope :legacy_artifacts, -> do
          where('artifacts_file IS NOT NULL AND artifacts_file <> ?', '')
        end

        scope :without_new_artifacts, -> do
          where('NOT EXISTS (SELECT 1 FROM ci_job_artifacts WHERE ci_job_artifacts.id = ci_builds.id AND (file_type = 1 OR file_type = 2))')
        end
      end

      class JobArtifact < ActiveRecord::Base
        self.table_name = 'ci_job_artifacts'

        LOCAL_STORE = 1 # Equavalant to ObjectStorage::Store::LOCAL

        enum file_type: {
          archive: 1,
          metadata: 2,
          trace: 3
        }

        ##
        # File location of the file
        # legacy_path: File.join(model.created_at.utc.strftime('%Y_%m'), model.project_id.to_s, model.id.to_s)
        # hashed_path: File.join(disk_hash[0..1], disk_hash[2..3], disk_hash, creation_date, model.job_id.to_s, model.id.to_s)
        enum file_location: {
          hashed_path: nil,
          legacy_path: 1
        }
      end

      def perform(start_id, stop_id)
        rows = []

        # Build rows
        MigrateLegacyArtifacts::Build
          .legacy_artifacts.without_new_artifacts
          .where(id: (start_id..stop_id)).find_each do |build|
          rows << build_archive_row(build)
          rows << build_metadata_row(build) if build.artifacts_metadata
        end

        # Bulk insert
        Gitlab::Database
          .bulk_insert(MigrateLegacyArtifacts::JobArtifact.table_name, rows)

        # Clean columns of ci_builds
        #
        # Included
        # "artifacts_file", "artifacts_metadata", "artifacts_size", "artifacts_file_store", "artifacts_metadata_store"
        # Excluded
        # - "artifacts_expire_at"
        # This is still used to process the expiration logic of job artifacts.
        # We also store the same value to `ci_job_artifacts.expire_at`, however it's not used at the moment.
        MigrateLegacyArtifacts::Build
          .legacy_artifacts
          .where(id: (start_id..stop_id))
          .update_all(artifacts_file: nil,
                      artifacts_file_store: nil,
                      artifacts_size: nil,
                      artifacts_metadata: nil,
                      artifacts_metadata_store: nil)
      end

      private

      def build_archive_row(build)
        build_base_row(build).merge({
          size: build.artifacts_size,
          file: build.artifacts_file,
          file_store: build.artifacts_file_store || JobArtifact::LOCAL_STORE,
          file_type: MigrateLegacyArtifacts::JobArtifact.file_types['archive'],
          file_sha256: nil # `file_sha256` of legacy artifacts had not been persisted
        })
      end

      def build_metadata_row(build)
        build_base_row(build).merge({
          size: nil, # `size` of legacy metadatas had not been persisted
          file: build.artifacts_metadata,
          file_store: build.artifacts_metadata_store || JobArtifact::LOCAL_STORE,
          file_type: MigrateLegacyArtifacts::JobArtifact.file_types['metadata'],
          file_sha256: nil # `file_sha256` of legacy artifacts had not been persisted
        })
      end

      def build_base_row(build)
        {
          project_id: build.project_id,
          job_id: build.id,
          expire_at: build.artifacts_expire_at,
          file_location: MigrateLegacyArtifacts::JobArtifact.file_locations['legacy_path'],
          created_at: build.created_at,
          updated_at: build.created_at
        }
      end
    end
  end
end
