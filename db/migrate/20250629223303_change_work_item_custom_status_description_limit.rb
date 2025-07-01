# frozen_string_literal: true

class ChangeWorkItemCustomStatusDescriptionLimit < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_8ea8b3c991'

  def up
    remove_text_limit :work_item_custom_statuses, :description, constraint_name: CONSTRAINT_NAME
    add_text_limit :work_item_custom_statuses, :description, 128, constraint_name: CONSTRAINT_NAME
  end

  def down
    remove_text_limit :work_item_custom_statuses, :description, constraint_name: CONSTRAINT_NAME
    add_text_limit :work_item_custom_statuses, :description, 255, constraint_name: CONSTRAINT_NAME
  end
end
