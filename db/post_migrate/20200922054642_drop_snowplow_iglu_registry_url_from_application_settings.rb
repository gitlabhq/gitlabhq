# frozen_string_literal: true

class DropSnowplowIgluRegistryUrlFromApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    remove_column :application_settings, :snowplow_iglu_registry_url, :string, limit: 255
  end
end
