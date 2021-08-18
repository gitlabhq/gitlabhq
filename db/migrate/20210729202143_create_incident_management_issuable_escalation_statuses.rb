# frozen_string_literal: true

class CreateIncidentManagementIssuableEscalationStatuses < ActiveRecord::Migration[6.1]
  ISSUE_IDX = 'index_uniq_im_issuable_escalation_statuses_on_issue_id'
  POLICY_IDX = 'index_im_issuable_escalation_statuses_on_policy_id'

  def change
    create_table :incident_management_issuable_escalation_statuses do |t|
      t.timestamps_with_timezone

      t.references :issue, foreign_key: { on_delete: :cascade }, index: { unique: true, name: ISSUE_IDX }, null: false
      t.references :policy, foreign_key: { to_table: :incident_management_escalation_policies, on_delete: :nullify }, index: { name: POLICY_IDX }

      t.datetime_with_timezone :escalations_started_at
      t.datetime_with_timezone :resolved_at

      t.integer :status, default: 0, null: false, limit: 2
    end
  end
end
