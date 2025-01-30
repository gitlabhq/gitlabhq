# frozen_string_literal: true

class AddWorkItemParentLinksNamespaceIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  def up
    add_not_null_constraint :work_item_parent_links, :namespace_id, validate: false
  end

  def down
    remove_not_null_constraint :work_item_parent_links, :namespace_id
  end
end
