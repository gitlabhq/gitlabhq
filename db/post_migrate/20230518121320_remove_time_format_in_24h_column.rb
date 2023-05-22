# frozen_string_literal: true

class RemoveTimeFormatIn24hColumn < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    remove_column :user_preferences, :time_format_in_24h
  end

  def down
    # rubocop:disable Migration/SchemaAdditionMethodsNoPost
    add_column :user_preferences, :time_format_in_24h, :boolean
    # rubocop:enable Migration/SchemaAdditionMethodsNoPost
  end
end
