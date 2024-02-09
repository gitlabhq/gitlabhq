# frozen_string_literal: true

class AddOrganizationIdToPushRules < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  INDEX_NAME = 'index_push_rules_on_organization_id'

  disable_ddl_transaction!

  def up
    add_column :push_rules, :organization_id, :bigint, null: true

    add_concurrent_index :push_rules, :organization_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :push_rules, INDEX_NAME

    remove_column :push_rules, :organization_id
  end
end
