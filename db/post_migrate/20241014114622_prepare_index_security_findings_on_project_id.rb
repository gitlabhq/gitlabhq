# frozen_string_literal: true

class PrepareIndexSecurityFindingsOnProjectId < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.6'
  disable_ddl_transaction!

  INDEX_NAME = 'index_security_findings_on_project_id'

  def up
    prepare_partitioned_async_index :security_findings, :project_id, name: INDEX_NAME
  end

  def down
    unprepare_partitioned_async_index_by_name :security_findings, INDEX_NAME
  end
end
