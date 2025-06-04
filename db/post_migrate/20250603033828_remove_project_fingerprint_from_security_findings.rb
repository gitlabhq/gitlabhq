# frozen_string_literal: true

class RemoveProjectFingerprintFromSecurityFindings < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.1'

  def up
    remove_check_constraint :security_findings, 'check_b9508c6df8'
    remove_column :security_findings, :project_fingerprint
  end

  def down
    add_column :security_findings, :project_fingerprint, :text, if_not_exists: true
    add_check_constraint :security_findings, 'char_length(project_fingerprint) <= 40', 'check_b9508c6df8'
    add_concurrent_partitioned_index :security_findings, :project_fingerprint,
      name: 'security_findings_project_fingerprint_idx'
  end
end
