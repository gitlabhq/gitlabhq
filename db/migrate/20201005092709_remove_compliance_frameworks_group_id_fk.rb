# frozen_string_literal: true

class RemoveComplianceFrameworksGroupIdFk < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_compliance_management_frameworks_on_group_id_and_name'.freeze

  class TmpComplianceFramework < ActiveRecord::Base
    self.table_name = 'compliance_management_frameworks'

    include EachBatch
  end

  disable_ddl_transaction!

  def up
    TmpComplianceFramework.each_batch(of: 100) do |query|
      query.update_all('namespace_id = group_id') # Copy data in case we rolled back before...
    end

    change_column_null(:compliance_management_frameworks, :group_id, true)

    remove_foreign_key_if_exists(:compliance_management_frameworks, :namespaces, column: :group_id)
    remove_concurrent_index_by_name(:compliance_management_frameworks, INDEX_NAME)
  end

  def down
    # This is just to make the rollback possible
    TmpComplianceFramework.each_batch(of: 100) do |query|
      query.update_all('group_id = namespace_id') # The group_id column is not in used at all
    end

    change_column_null(:compliance_management_frameworks, :group_id, false)

    add_concurrent_foreign_key(:compliance_management_frameworks, :namespaces, column: :group_id, on_delete: :cascade)
    add_concurrent_index(:compliance_management_frameworks, [:group_id, :name], unique: true, name: INDEX_NAME)
  end
end
