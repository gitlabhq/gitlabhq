# frozen_string_literal: true

class AddStateToOrganizations < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.11'

  INDEX_NAME = 'index_organizations_on_state'

  def up
    with_lock_retries do
      add_column :organizations, :state, :smallint, null: false, default: 0, if_not_exists: true
    end

    add_concurrent_index :organizations, :state, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :organizations, INDEX_NAME

    with_lock_retries do
      remove_column :organizations, :state, if_exists: true
    end
  end
end
