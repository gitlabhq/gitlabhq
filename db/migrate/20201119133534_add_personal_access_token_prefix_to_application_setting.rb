# frozen_string_literal: true

class AddPersonalAccessTokenPrefixToApplicationSetting < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20201119133604_add_text_limit_to_application_setting_personal_access_token_prefix
  def change
    add_column :application_settings, :personal_access_token_prefix, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
