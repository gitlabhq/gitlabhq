# frozen_string_literal: true

class AddGitpodApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20200727154631_add_gitpod_application_settings_text_limit
  def change
    add_column :application_settings, :gitpod_enabled, :boolean, default: false, null: false
    add_column :application_settings, :gitpod_url, :text, default: 'https://gitpod.io/', null: true
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
