# frozen_string_literal: true

class AddMinimumAccessLevelExecuteAsyncToAiSettings < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def change
    add_column :ai_settings, :minimum_access_level_execute_async, :integer, limit: 2, null: true
  end
end
