# frozen_string_literal: true

class AddSdrsConfiguration < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :application_settings, :sdrs_url, :text, if_not_exists: true
      add_column :application_settings, :sdrs_enabled, :boolean, default: false,
        null: false, if_not_exists: true

      add_column :application_settings, :sdrs_jwt_signing_key, :jsonb, null: true, if_not_exists: true
    end

    add_text_limit :application_settings, :sdrs_url, 255
  end

  def down
    with_lock_retries do
      remove_column :application_settings, :sdrs_url
      remove_column :application_settings, :sdrs_enabled
      remove_column :application_settings, :sdrs_jwt_signing_key
    end
  end
end
