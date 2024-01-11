# frozen_string_literal: true

class AddTextLimitToCiInstanceVariablesDescription < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  disable_ddl_transaction!

  TABLE_NAME = :ci_instance_variables
  COLUMN_NAME = :description

  def up
    add_text_limit(TABLE_NAME, COLUMN_NAME, 255)
  end

  def down
    remove_text_limit(TABLE_NAME, COLUMN_NAME)
  end
end
