# frozen_string_literal: true

class AddActiveContextSettingsToApplicationSettings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.0'

  def up
    with_lock_retries do
      add_column :application_settings, :active_context_settings, :jsonb, default: {}, null: false, if_not_exists: true
    end
  end

  def down
    with_lock_retries do
      remove_column :application_settings, :active_context_settings, if_exists: true
    end
  end
end
