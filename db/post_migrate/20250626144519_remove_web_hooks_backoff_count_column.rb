# frozen_string_literal: true

class RemoveWebHooksBackoffCountColumn < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  TABLE_NAME = :web_hooks
  COLUMN_NAME = :backoff_count

  def up
    remove_column TABLE_NAME, COLUMN_NAME
  end

  def down
    add_column TABLE_NAME, COLUMN_NAME, :smallint, default: 0, null: false
  end
end
