# frozen_string_literal: true

class AddKrokiApplicationSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20201011005400_add_text_limit_to_application_settings_kroki_url.rb
  #
  def change
    add_column :application_settings, :kroki_url, :text
    add_column :application_settings, :kroki_enabled, :boolean, default: false, null: false
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
