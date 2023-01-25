# frozen_string_literal: true

class AddDeactivationEmailAdditionalTextToApplicationSettingsTextLimits < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_text_limit :application_settings, :deactivation_email_additional_text, 1000
  end

  def down
    remove_text_limit :application_settings, :deactivation_email_additional_text
  end
end
