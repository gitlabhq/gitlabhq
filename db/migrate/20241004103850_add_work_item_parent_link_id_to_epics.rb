# frozen_string_literal: true

class AddWorkItemParentLinkIdToEpics < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def up
    add_column :epics, :work_item_parent_link_id, :bigint
  end

  def down
    remove_column :epics, :work_item_parent_link_id, if_exists: true
  end
end
