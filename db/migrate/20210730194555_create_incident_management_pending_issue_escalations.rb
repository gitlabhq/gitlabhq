# frozen_string_literal: true

class CreateIncidentManagementPendingIssueEscalations < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      execute(<<~SQL)
        CREATE TABLE incident_management_pending_issue_escalations (
          id bigserial NOT NULL,
          rule_id bigint  NOT NULL,
          issue_id bigint NOT NULL,
          process_at timestamp with time zone NOT NULL,
          created_at timestamp with time zone NOT NULL,
          updated_at timestamp with time zone NOT NULL,
          PRIMARY KEY (id, process_at)
        ) PARTITION BY RANGE (process_at);

        CREATE INDEX index_incident_management_pending_issue_escalations_on_issue_id
          ON incident_management_pending_issue_escalations USING btree (issue_id);

        CREATE INDEX index_incident_management_pending_issue_escalations_on_rule_id
          ON incident_management_pending_issue_escalations USING btree (rule_id);
      SQL
    end
  end

  def down
    with_lock_retries do
      drop_table :incident_management_pending_issue_escalations
    end
  end
end
