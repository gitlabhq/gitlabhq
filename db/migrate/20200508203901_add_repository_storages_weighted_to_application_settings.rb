# frozen_string_literal: true

class AddRepositoryStoragesWeightedToApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    add_column :application_settings, :repository_storages_weighted, :jsonb, default: {}, null: false
  end

  def down
    remove_column :application_settings, :repository_storages_weighted
  end
end
