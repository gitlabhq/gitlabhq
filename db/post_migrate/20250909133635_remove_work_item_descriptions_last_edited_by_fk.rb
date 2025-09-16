# frozen_string_literal: true

class RemoveWorkItemDescriptionsLastEditedByFk < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  def up
    return unless table_exists?(:work_item_descriptions)

    with_lock_retries do
      remove_foreign_key_if_exists(:work_item_descriptions, :users, column: :last_edited_by_id)
    end
  end

  def down
    # We want to drop the table, no need to recreate the foreign key here
  end
end
