# frozen_string_literal: true

class RemoveSingletonFromAiSettings < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  disable_ddl_transaction!

  INDEX_NAME = :index_ai_settings_on_singleton

  def up
    remove_check_constraint :ai_settings, 'check_singleton'
    remove_concurrent_index_by_name :ai_settings, INDEX_NAME
  end

  def down
    # no-op: singleton enforcement cannot be safely restored after org-scoped rows
  end
end
