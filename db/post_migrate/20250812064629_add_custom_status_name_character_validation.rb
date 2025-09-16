# frozen_string_literal: true

class AddCustomStatusNameCharacterValidation < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  CONSTRAINT_NAME = 'check_custom_status_name_characters'

  def up
    add_check_constraint(
      :work_item_custom_statuses,
      "name !~ '^[\"''`]|[\"''`]$|[\\x00-\\x1F\\x7F]'",
      CONSTRAINT_NAME,
      validate: false
    )
  end

  def down
    remove_check_constraint(:work_item_custom_statuses, CONSTRAINT_NAME)
  end
end
