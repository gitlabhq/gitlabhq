# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillIssueCustomerRelationsContactsNamespaceId < BackfillDesiredShardingKeyJob
      operation_name :backfill_issue_customer_relations_contacts_namespace_id
      feature_category :service_desk
    end
  end
end
