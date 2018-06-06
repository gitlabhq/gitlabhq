# frozen_string_literal: true
# rubocop:disable Metrics/AbcSize
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class MigrateLegacyArtifacts
      class Build < ActiveRecord::Base
        include EachBatch

        self.table_name = 'ci_builds'
        self.inheritance_column = :_type_disabled

        scope :with_legacy_artifacts, -> { where("artifacts_file <> '' AND artifacts_metadata <> ''") }

        scope :without_new_artifacts, -> do
          where('NOT EXISTS (SELECT 1 FROM ci_job_artifacts WHERE (ci_builds.id = ci_job_artifacts.job_id) AND ci_job_artifacts.file_type = 1)')
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
        ActiveRecord::Base.transaction do
          insert_archives(start_id, stop_id)
          insert_metadatas(start_id, stop_id)
          delete_legacy_artifacts(start_id, stop_id)
        end
      end

      private

      def insert_archives(start_id, stop_id)
        ActiveRecord::Base.connection.execute <<-EOF.strip_heredoc
          INSERT INTO ci_job_artifacts (
                project_id,
                job_id,
                expire_at,
                file_location,
                created_at,
                updated_at,
                file,
                size,
                file_store,
                file_type)
          SELECT project_id,
                id,
                artifacts_expire_at,
                #{MigrateLegacyArtifacts::JobArtifact.file_locations['legacy_path']},
                created_at,
                created_at,
                artifacts_file,
                artifacts_size,
                COALESCE(artifacts_file_store, #{JobArtifact::LOCAL_STORE}),
                #{MigrateLegacyArtifacts::JobArtifact.file_types['archive']}
            FROM ci_builds
          WHERE id BETWEEN #{start_id.to_i} AND #{stop_id.to_i}
                  AND artifacts_file <> ''
                  AND NOT EXISTS (
                    SELECT 1 FROM ci_job_artifacts
                    WHERE (ci_builds.id = ci_job_artifacts.job_id)
                      AND ci_job_artifacts.file_type = #{MigrateLegacyArtifacts::JobArtifact.file_types['archive']})
        EOF
      end

      def insert_metadatas(start_id, stop_id)
        ActiveRecord::Base.connection.execute <<-EOF.strip_heredoc
          INSERT INTO ci_job_artifacts (
                project_id,
                job_id,
                expire_at,
                file_location,
                created_at,
                updated_at,
                file,
                size,
                file_store,
                file_type)
          SELECT project_id,
                id,
                artifacts_expire_at,
                #{MigrateLegacyArtifacts::JobArtifact.file_locations['legacy_path']},
                created_at,
                created_at,
                artifacts_metadata,
                NULL,
                COALESCE(artifacts_metadata_store, #{JobArtifact::LOCAL_STORE}),
                #{MigrateLegacyArtifacts::JobArtifact.file_types['metadata']}
            FROM ci_builds
          WHERE id BETWEEN #{start_id.to_i} AND #{stop_id.to_i}
                  AND artifacts_file <> '' AND artifacts_metadata <> ''
                  AND NOT EXISTS (
                    SELECT 1 FROM ci_job_artifacts
                    WHERE (ci_builds.id = ci_job_artifacts.job_id)
                      AND ci_job_artifacts.file_type = #{MigrateLegacyArtifacts::JobArtifact.file_types['metadata']})
        EOF
      end

      def delete_legacy_artifacts(start_id, stop_id)
        ActiveRecord::Base.connection.execute <<-EOF.strip_heredoc
          UPDATE ci_builds SET
                  artifacts_file = NULL, artifacts_size = NULL, artifacts_file_store = NULL,
                  artifacts_metadata = NULL, artifacts_metadata_store = NULL
          WHERE id BETWEEN #{start_id.to_i} AND #{stop_id.to_i}
                  AND (artifacts_file <> '' OR artifacts_metadata <> '')
        EOF
      end
    end
  end
end
