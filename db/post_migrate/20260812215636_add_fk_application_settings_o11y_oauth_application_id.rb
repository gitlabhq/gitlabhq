# frozen_string_literal: true

class AddFkApplicationSettingsO11yOauthApplicationId < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :application_settings, :oauth_applications,
      column: :o11y_oauth_application_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :application_settings, :oauth_applications,
        column: :o11y_oauth_application_id
    end
  end
end
