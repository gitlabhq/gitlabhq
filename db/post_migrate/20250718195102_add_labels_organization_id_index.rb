# frozen_string_literal: true

class AddLabelsOrganizationIdIndex < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'index_labels_on_organization_id'

  disable_ddl_transaction!
  milestone '18.3'

  def up
    add_concurrent_index :labels, :organization_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :labels, :organization_id, name: INDEX_NAME
  end
end
