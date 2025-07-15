# frozen_string_literal: true

class AddImportersToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def change
    add_column :application_settings, :importers, :jsonb, default: {}, null: false
  end
end
