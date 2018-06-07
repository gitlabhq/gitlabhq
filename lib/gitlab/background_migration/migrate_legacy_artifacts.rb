# frozen_string_literal: true
# rubocop:disable Metrics/AbcSize
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class MigrateLegacyArtifacts
      FILE_LOCAL_STORE = 1 # equal to ObjectStorage::Store::LOCAL
      ARCHIVE_FILE_TYPE = 1 # equal to Ci::JobArtifact.file_types['archive']
      METADATA_FILE_TYPE = 2 # equal to Ci::JobArtifact.file_types['metadata']
      LEGACY_PATH_FILE_LOCATION = 1 # equal to Ci::JobArtifact.file_location['legacy_path']

      def perform(id_list)
        ActiveRecord::Base.transaction do
          insert_archives(id_list)
          insert_metadatas(id_list)
          delete_legacy_artifacts(id_list)
        end
      end

      private

      def insert_archives(id_list)
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
                #{LEGACY_PATH_FILE_LOCATION},
                created_at,
                created_at,
                artifacts_file,
                artifacts_size,
                COALESCE(artifacts_file_store, #{FILE_LOCAL_STORE}),
                #{ARCHIVE_FILE_TYPE}
            FROM ci_builds
          WHERE id IN (#{id_list.join(',')})
                  AND artifacts_file <> ''
                  AND NOT EXISTS (
                    SELECT 1 FROM ci_job_artifacts
                    WHERE (ci_builds.id = ci_job_artifacts.job_id)
                      AND ci_job_artifacts.file_type = #{ARCHIVE_FILE_TYPE})
        EOF
      end

      def insert_metadatas(id_list)
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
                #{LEGACY_PATH_FILE_LOCATION},
                created_at,
                created_at,
                artifacts_metadata,
                NULL,
                COALESCE(artifacts_metadata_store, #{FILE_LOCAL_STORE}),
                #{METADATA_FILE_TYPE}
            FROM ci_builds
          WHERE id IN (#{id_list.join(',')})
                  AND artifacts_file <> '' AND artifacts_metadata <> ''
                  AND NOT EXISTS (
                    SELECT 1 FROM ci_job_artifacts
                    WHERE (ci_builds.id = ci_job_artifacts.job_id)
                      AND ci_job_artifacts.file_type = #{METADATA_FILE_TYPE})
        EOF
      end

      def delete_legacy_artifacts(id_list)
        ActiveRecord::Base.connection.execute <<-EOF.strip_heredoc
          UPDATE ci_builds
             SET artifacts_file = NULL,
                 artifacts_file_store = NULL,
                 artifacts_size = NULL,
                 artifacts_metadata = NULL,
                 artifacts_metadata_store = NULL
           WHERE id IN (#{id_list.join(',')})
                  AND (artifacts_file <> '' OR artifacts_metadata <> '')
        EOF
      end
    end
  end
end
