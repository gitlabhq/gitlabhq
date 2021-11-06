# frozen_string_literal: true

class AddTextLimitToApplicationSettingsContentValidationEndpointUrl < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit :application_settings, :content_validation_endpoint_url, 255
  end

  def down
    remove_text_limit :application_settings, :content_validation_endpoint_url
  end
end
