# frozen_string_literal: true

class AddProjectDefaultsToApplicationSettings < Gitlab::Database::Migration[2.4]
  milestone '19.6'

  def change
    add_column :application_settings, :project_defaults, :jsonb, default: {}, null: false
  end
end
