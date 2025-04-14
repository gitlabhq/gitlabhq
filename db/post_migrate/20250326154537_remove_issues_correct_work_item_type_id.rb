# frozen_string_literal: true

class RemoveIssuesCorrectWorkItemTypeId < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def up
    remove_column :issues, :correct_work_item_type_id
  end

  def down
    add_column :issues, :correct_work_item_type_id, :bigint
  end
end
