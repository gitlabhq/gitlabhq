# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillIssueEmailParticipantsNamespaceId < BackfillDesiredShardingKeyJob
      operation_name :backfill_issue_email_participants_namespace_id
      feature_category :service_desk
    end
  end
end
