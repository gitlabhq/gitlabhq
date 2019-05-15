# frozen_string_literal: true

class AddApplicationSettingsElasticsearchShards < ActiveRecord::Migration[5.1]
  DOWNTIME = false

  def change
    add_column :application_settings, :elasticsearch_shards, :integer, null: false, default: 5
    add_column :application_settings, :elasticsearch_replicas, :integer, null: false, default: 1
  end
end
