# frozen_string_literal: true

class AddIndexApplicationSettingsO11yOauthApplicationId < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!

  def up
    add_concurrent_index :application_settings,
      :o11y_oauth_application_id,
      name: :idx_application_settings_on_o11y_oauth_application_id
  end

  def down
    remove_concurrent_index_by_name :application_settings,
      :idx_application_settings_on_o11y_oauth_application_id
  end
end
