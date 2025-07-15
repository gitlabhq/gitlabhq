# frozen_string_literal: true

class ChangeWorkItemCustomLifecycleNameLimit < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_1feff2de99'

  def up
    remove_text_limit :work_item_custom_lifecycles, :name, constraint_name: CONSTRAINT_NAME
    add_text_limit :work_item_custom_lifecycles, :name, 64, constraint_name: CONSTRAINT_NAME
  end

  def down
    remove_text_limit :work_item_custom_lifecycles, :name, constraint_name: CONSTRAINT_NAME
    add_text_limit :work_item_custom_lifecycles, :name, 255, constraint_name: CONSTRAINT_NAME
  end
end
