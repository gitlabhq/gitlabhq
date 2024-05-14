# frozen_string_literal: true

class AddNamespaceIdToWorkItemParentLinks < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def change
    add_column :work_item_parent_links, :namespace_id, :bigint
  end
end
