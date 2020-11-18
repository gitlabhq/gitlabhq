# frozen_string_literal: true

class AddTextLimitToSecretDetectionRevocationTokenTypesApplicationSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_text_limit :application_settings, :secret_detection_revocation_token_types_url, 255
  end

  def down
    remove_text_limit :application_settings, :secret_detection_revocation_token_types_url
  end
end
