# frozen_string_literal: true
# rubocop:disable Metrics/AbcSize
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class MigrateLegacyArtifacts
      class Build < ActiveRecord::Base
        self.table_name = 'ci_builds'
        self.inheritance_column = :_type_disabled

        scope :legacy_artifacts, -> { where('artifacts_file IS NOT NULL OR artifacts_file <> ?', '') }
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

        MigrateLegacyArtifacts::Build
          .legacy_artifacts
          .where(id: (start_id..stop_id)).each do |build|
          base_param = {
            project_id: build.project_id,
            job_id: build.id,
            expire_at: build.artifacts_expire_at,
            file_location: MigrateLegacyArtifacts::JobArtifact.file_locations['legacy_path'],
            created_at: build.created_at,
            updated_at: build.created_at
          }

          rows << base_param.merge({
            size: build.artifacts_size,
            file: build.artifacts_file,
            file_store: build.artifacts_file_store || JobArtifact::LOCAL_STORE,
            file_type: MigrateLegacyArtifacts::JobArtifact.file_types['archive'],
            file_sha256: nil # `file_sha256` of legacy artifacts had not been persisted
          })

          if build.artifacts_metadata
            rows << base_param.merge({
              size: get_legacy_metadata_size(build), # `size` of legacy metadatas had not been persisted
              file: build.artifacts_metadata,
              file_store: build.artifacts_metadata_store || JobArtifact::LOCAL_STORE,
              file_type: MigrateLegacyArtifacts::JobArtifact.file_types['metadata'],
              file_sha256: nil # `file_sha256` of legacy artifacts had not been persisted
            })
          end
        end

        Gitlab::Database
          .bulk_insert(MigrateLegacyArtifacts::JobArtifact.table_name, rows)

        # TODO: Do we need to verify the file existance with created job artifacts?

        # Clean columns of ci_builds
        #
        # Targets
        # "artifacts_file"
        # "artifacts_metadata"
        # "artifacts_size"
        # "artifacts_file_store"
        # Ignore
        # "artifacts_expire_at" ,,, This is widely used for showing expiration time of artifacts
        MigrateLegacyArtifacts::Build
          .legacy_artifacts
          .where(id: (start_id..stop_id))
          .update_all(artifacts_file: nil,
                      artifacts_metadata: nil,
                      artifacts_size: nil,
                      artifacts_file_store: nil)
      end

      private

      ##
      # This method is efficient that request with HEAD method and get content-length,
      # instead of pulling the whole data
      def get_legacy_metadata_size(build)
        legacy_file_path = File.join(build.created_at.utc.strftime('%Y_%m'), build.project_id.to_s, build.id.to_s, build.legacy_artifacts_metadata)

        10 # TODO:
      end
    end
  end
end
