# frozen_string_literal: true

class AddIncludeForFreeUserCapPreviewToNamespaceSettings < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def up
    add_column :namespace_settings, :include_for_free_user_cap_preview, :boolean, null: false, default: false
  end

  def down
    remove_column :namespace_settings, :include_for_free_user_cap_preview
  end
end
