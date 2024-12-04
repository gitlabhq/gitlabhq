# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillIssueEmailsNamespaceId < BackfillDesiredShardingKeyJob
      operation_name :backfill_issue_emails_namespace_id
      feature_category :service_desk
    end
  end
end
