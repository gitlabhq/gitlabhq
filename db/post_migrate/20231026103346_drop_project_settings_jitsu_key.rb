# frozen_string_literal: true

class DropProjectSettingsJitsuKey < Gitlab::Database::Migration[2.2]
  milestone '16.6'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_column :project_settings, :jitsu_key, if_exists: true
    end
  end

  def down
    with_lock_retries do
      add_column :project_settings, :jitsu_key, :text, if_not_exists: true
    end

    add_text_limit :project_settings, :jitsu_key, 100
  end
end
