# frozen_string_literal: true

class DropIndexSecurityFindingsConfidenceIdx < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '17.2'

  INDEX_NAME = 'security_findings_confidence_idx'
  TABLE_NAME = :security_findings

  def up
    remove_concurrent_partitioned_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    add_concurrent_partitioned_index TABLE_NAME, :confidence, name: INDEX_NAME
  end
end
