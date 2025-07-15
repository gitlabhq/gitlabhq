# frozen_string_literal: true

class ChangeWorkItemCustomStatusNameLimit < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_720a7c4d24'

  def up
    remove_text_limit :work_item_custom_statuses, :name, constraint_name: CONSTRAINT_NAME
    add_text_limit :work_item_custom_statuses, :name, 32, constraint_name: CONSTRAINT_NAME
  end

  def down
    remove_text_limit :work_item_custom_statuses, :name, constraint_name: CONSTRAINT_NAME
    add_text_limit :work_item_custom_statuses, :name, 255, constraint_name: CONSTRAINT_NAME
  end
end
