# frozen_string_literal: true

class UpdateEscalationRuleFkForPendingAlertEscalations < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  OLD_FOREIGN_KEY_CONSTRAINT = 'fk_rails_057c1e3d87'

  # Swap foreign key contrainst from ON DELETE SET NULL to ON DELETE CASCADE
  def up
    remove_foreign_key_if_exists :incident_management_pending_alert_escalations, :incident_management_escalation_rules, name: OLD_FOREIGN_KEY_CONSTRAINT

    add_concurrent_partitioned_foreign_key :incident_management_pending_alert_escalations,
      :incident_management_escalation_rules,
      column: :rule_id
  end

  def down
    remove_foreign_key_if_exists :incident_management_pending_alert_escalations, :incident_management_escalation_rules, column: :rule_id

    add_concurrent_partitioned_foreign_key :incident_management_pending_alert_escalations,
      :incident_management_escalation_rules,
      column: :rule_id,
      on_delete: :nullify,
      name: OLD_FOREIGN_KEY_CONSTRAINT
  end
end
