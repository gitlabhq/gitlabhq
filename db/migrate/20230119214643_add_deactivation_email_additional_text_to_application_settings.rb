# frozen_string_literal: true

class AddDeactivationEmailAdditionalTextToApplicationSettings < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20230123150648_add_deactivation_email_additional_text_to_application_settings_text_limits.rb
  def change
    add_column :application_settings, :deactivation_email_additional_text, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
