# frozen_string_literal: true

class AddTextLimitToSecretDetectionTokenRevocationApplicationSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_text_limit :application_settings, :secret_detection_token_revocation_url, 255
  end

  def down
    remove_text_limit :application_settings, :secret_detection_token_revocation_url
  end
end
