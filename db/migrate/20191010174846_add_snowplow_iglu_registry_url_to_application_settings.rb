# frozen_string_literal: true

class AddSnowplowIgluRegistryUrlToApplicationSettings < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    add_column :application_settings, :snowplow_iglu_registry_url, :string, limit: 255
  end
  # rubocop:enable Migration/PreventStrings
end
