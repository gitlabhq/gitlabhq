# frozen_string_literal: true

class AddSecretDetectionRevocationTokenTypesApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    add_column :application_settings, :secret_detection_revocation_token_types_url, :text, null: true # rubocop:disable Migration/AddLimitToTextColumns
  end

  def down
    remove_column :application_settings, :secret_detection_revocation_token_types_url
  end
end
