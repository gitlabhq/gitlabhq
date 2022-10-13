# frozen_string_literal: true

class RemoveNamespaceSettingsCohortFreeUserCapColumns < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def up
    remove_column :namespace_settings, :exclude_from_free_user_cap
    remove_column :namespace_settings, :include_for_free_user_cap_preview
  end

  def down
    add_column :namespace_settings, :exclude_from_free_user_cap, :boolean, null: false, default: false
    add_column :namespace_settings, :include_for_free_user_cap_preview, :boolean, null: false, default: false
  end
end
