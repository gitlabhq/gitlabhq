# frozen_string_literal: true

class AddIframeAllowlistToApplicationSettings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    with_lock_retries do
      add_column :application_settings, :iframe_rendering_enabled, :boolean, default: false, null: false,
        if_not_exists: true
      add_column :application_settings, :iframe_rendering_allowlist, :text, if_not_exists: true
    end

    # Limit size of the allowlist text column for safety
    add_text_limit :application_settings, :iframe_rendering_allowlist, 5000
  end

  def down
    with_lock_retries do
      remove_column :application_settings, :iframe_rendering_allowlist, if_exists: true
      remove_column :application_settings, :iframe_rendering_enabled, if_exists: true
    end
  end
end
