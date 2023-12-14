# frozen_string_literal: true

class AddTrigramIndexToComplianceManagementFrameworksOnName < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  disable_ddl_transaction!

  INDEX_NAME = 'index_compliance_management_frameworks_on_name_trigram'

  def up
    add_concurrent_index :compliance_management_frameworks, :name,
      name: INDEX_NAME,
      using: :gin, opclass: { name: :gin_trgm_ops }
  end

  def down
    remove_concurrent_index_by_name :compliance_management_frameworks, INDEX_NAME
  end
end
