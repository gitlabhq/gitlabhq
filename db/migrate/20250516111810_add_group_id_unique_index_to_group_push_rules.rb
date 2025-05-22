# frozen_string_literal: true

class AddGroupIdUniqueIndexToGroupPushRules < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'index_group_push_rules_on_group_id'

  disable_ddl_transaction!
  milestone '18.1'

  def up
    # remove existing non-unique index if it exists
    if index_exists?(:group_push_rules, :group_id, name: INDEX_NAME)
      remove_concurrent_index :group_push_rules, :group_id, name: INDEX_NAME
    end

    add_concurrent_index :group_push_rules, :group_id, unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :group_push_rules, :group_id, name: INDEX_NAME

    # re-add previous non-unique index
    add_concurrent_index :group_push_rules, :group_id, name: INDEX_NAME
  end
end
