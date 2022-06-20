# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
class AddGloballyAllowedIpsToApplicationSetting < Gitlab::Database::Migration[2.0]
  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20220516123101_add_text_limit_to_globally_allowed_ips_on_application_settings
  def change
    add_column :application_settings, :globally_allowed_ips, :text, null: false, default: ""
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
