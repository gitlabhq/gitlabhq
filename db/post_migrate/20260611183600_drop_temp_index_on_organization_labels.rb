# frozen_string_literal: true

class DropTempIndexOnOrganizationLabels < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'tmp_idx_labels_with_organization_id'

  disable_ddl_transaction!
  milestone '19.2'

  def up
    remove_concurrent_index :labels, :id, name: INDEX_NAME
  end

  def down
    add_concurrent_index :labels, :id, name: INDEX_NAME, where: 'organization_id IS NOT NULL'
  end
end
