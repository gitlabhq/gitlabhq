# frozen_string_literal: true

class AddIndexToSecurityFindingsUuid < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_security_findings_on_uuid'

  disable_ddl_transaction!

  def up
    add_concurrent_index :security_findings, :uuid, name: INDEX_NAME, unique: true
  end

  def down
    remove_concurrent_index_by_name :security_findings, INDEX_NAME
  end
end
