# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # BackfillIncidentIssueEscalationStatuses adds
    # IncidentManagement::IssuableEscalationStatus records for existing Incident issues.
    # They will be added with no policy, and escalations_started_at as nil.
    class BackfillIncidentIssueEscalationStatuses
      def perform(start_id, stop_id)
        ActiveRecord::Base.connection.execute <<~SQL
          INSERT INTO incident_management_issuable_escalation_statuses (issue_id, created_at, updated_at)
            SELECT issues.id, current_timestamp, current_timestamp
            FROM issues
            WHERE issues.issue_type = 1
            AND issues.id BETWEEN #{start_id} AND #{stop_id}
            ON CONFLICT (issue_id) DO NOTHING;
        SQL

        mark_job_as_succeeded(start_id, stop_id)
      end

      private

      def mark_job_as_succeeded(*arguments)
        ::Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
          self.class.name.demodulize,
          arguments
        )
      end
    end
  end
end
