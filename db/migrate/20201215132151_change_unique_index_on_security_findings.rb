# frozen_string_literal: true

class ChangeUniqueIndexOnSecurityFindings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  OLD_INDEX_NAME = 'index_security_findings_on_uuid'
  NEW_INDEX_NAME = 'index_security_findings_on_uuid_and_scan_id'

  disable_ddl_transaction!

  class SecurityFinding < ActiveRecord::Base
    include EachBatch

    self.table_name = 'security_findings'
  end

  def up
    add_concurrent_index :security_findings, [:uuid, :scan_id], unique: true, name: NEW_INDEX_NAME

    remove_concurrent_index_by_name :security_findings, OLD_INDEX_NAME
  end

  def down
    # It is very unlikely that we rollback this migration but just in case if we have to,
    # we have to clear the table because there can be multiple records with the same UUID
    # which would break the creation of unique index on the `uuid` column.
    # We choose clearing the table because just removing the duplicated records would
    # cause data inconsistencies.
    SecurityFinding.each_batch(of: 10000) { |relation| relation.delete_all }

    add_concurrent_index :security_findings, :uuid, unique: true, name: OLD_INDEX_NAME

    remove_concurrent_index_by_name :security_findings, NEW_INDEX_NAME
  end
end
