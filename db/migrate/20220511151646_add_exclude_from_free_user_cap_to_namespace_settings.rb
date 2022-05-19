# frozen_string_literal: true

class AddExcludeFromFreeUserCapToNamespaceSettings < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def up
    add_column :namespace_settings, :exclude_from_free_user_cap, :boolean, null: false, default: false
  end

  def down
    remove_column :namespace_settings, :exclude_from_free_user_cap
  end
end
