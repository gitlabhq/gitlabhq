# frozen_string_literal: true

class AddIndexSecurityFindingsOnScanIdSeverityAndId < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '19.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_security_findings_on_scan_id_and_severity_and_id'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- https://gitlab.com/gitlab-org/database-team/team-tasks/-/work_items/637
    add_concurrent_partitioned_index :security_findings, [:scan_id, :severity, :id], name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_partitioned_index_by_name :security_findings, INDEX_NAME
  end
end
