# frozen_string_literal: true

class AddTextLimitToCiVariableDescription < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAME = :ci_variables
  COLUMN_NAME = :description

  def up
    add_text_limit(TABLE_NAME, COLUMN_NAME, 255)
  end

  def down
    remove_text_limit(TABLE_NAME, COLUMN_NAME)
  end
end
