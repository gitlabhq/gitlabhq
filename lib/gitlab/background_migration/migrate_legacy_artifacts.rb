# frozen_string_literal: true
# rubocop:disable Metrics/AbcSize
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class MigrateLegacyArtifacts
      class Build < ActiveRecord::Base
        self.table_name = 'ci_builds'
        self.inheritance_column = :_type_disabled

        scope :legacy_artifacts, -> { where('artifacts_file IS NOT NULL AND artifacts_file <> ?', '') }
      end

      class JobArtifact < ActiveRecord::Base
        self.table_name = 'ci_job_artifacts'

        enum file_type: {
          archive: 1,
          metadata: 2,
          trace: 3
        }
    
        enum path_type: {
          era_2: nil,
          era_1: 1
        }
      end

      def perform(start_id, stop_id)
        rows = []

        Gitlab::BackgroundMigration::MigrateLegacyArtifacts::Build.legacy_artifacts
          .where(id: (start_id..stop_id))
          .each do |build|
            base_param = {
              project_id: build.project_id,
              job_id: build.id,
              expire_at: build.artifacts_expire_at,
              path_type: Gitlab::BackgroundMigration::MigrateLegacyArtifacts::JobArtifact.path_types['era_1'],
              created_at: build.created_at,
              updated_at: build.created_at
            }

            rows << base_param.merge({
              size: build.artifacts_size,
              file: build.artifacts_file,
              file_store: build.artifacts_file_store,
              file_type: Gitlab::BackgroundMigration::MigrateLegacyArtifacts::JobArtifact.file_types['archive'],
              file_sha256: nil # `file_sha256` of legacy artifacts had not been persisted
            })

            if build.legacy_artifacts_metadata.exists?
              rows << base_param.merge({
                size: nil, # `size`` of legacy metadatas had not been persisted
                file: build.artifacts_metadata,
                file_store: build.artifacts_metadata_store,
                file_type: Gitlab::BackgroundMigration::MigrateLegacyArtifacts::JobArtifact.file_types['metadata'],
                file_sha256: nil # `file_sha256` of legacy artifacts had not been persisted
              })
            end
          end

          Gitlab::Database.bulk_insert(
            Gitlab::BackgroundMigration::MigrateLegacyArtifacts::JobArtifact.table_name,
            rows)
      end
    end
  end
end
