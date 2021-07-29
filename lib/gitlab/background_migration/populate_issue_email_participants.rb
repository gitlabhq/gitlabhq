# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Class to migrate service_desk_reply_to email addresses to issue_email_participants
    class PopulateIssueEmailParticipants
      # rubocop:disable Style/Documentation
      class TmpIssue < ActiveRecord::Base
        self.table_name = 'issues'
      end

      def perform(start_id, stop_id)
        issues = TmpIssue.select(:id, :service_desk_reply_to, :created_at).where(id: (start_id..stop_id)).where.not(service_desk_reply_to: nil)

        rows = issues.map do |issue|
          {
            issue_id: issue.id,
            email: issue.service_desk_reply_to,
            created_at: issue.created_at,
            updated_at: issue.created_at
          }
        end

        Gitlab::Database.main.bulk_insert(:issue_email_participants, rows, on_conflict: :do_nothing) # rubocop:disable Gitlab/BulkInsert
      end
    end
  end
end
