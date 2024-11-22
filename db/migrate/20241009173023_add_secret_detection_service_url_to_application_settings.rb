# frozen_string_literal: true

class AddSecretDetectionServiceUrlToApplicationSettings < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone "17.6"

  def up
    add_column :application_settings,
      :secret_detection_service_url,
      :text, default: "",
      null: false,
      if_not_exists: true

    add_text_limit :application_settings, :secret_detection_service_url, 255
  end

  def down
    remove_column :application_settings, :secret_detection_service_url, if_exists: true
  end
end
