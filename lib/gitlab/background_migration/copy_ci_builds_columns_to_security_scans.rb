# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class CopyCiBuildsColumnsToSecurityScans
      extend ::Gitlab::Utils::Override

      UPDATE_BATCH_SIZE = 500

      def perform(start_id, stop_id)
        (start_id..stop_id).step(UPDATE_BATCH_SIZE).each do |offset|
          batch_start = offset
          batch_stop = offset + UPDATE_BATCH_SIZE - 1

          ActiveRecord::Base.connection.execute <<~SQL
            UPDATE
              security_scans
            SET
              project_id = ci_builds.project_id,
              pipeline_id = ci_builds.commit_id
            FROM ci_builds
            WHERE ci_builds.type='Ci::Build' 
              AND ci_builds.id=security_scans.build_id 
              AND security_scans.id BETWEEN #{Integer(batch_start)} AND #{Integer(batch_stop)}
          SQL
        end

        mark_job_as_succeeded(start_id, stop_id)
      rescue StandardError => error
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(error)
      end

      private

      def mark_job_as_succeeded(*arguments)
        Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
          'CopyCiBuildsColumnsToSecurityScans',
          arguments
        )
      end
    end
  end
end
