# frozen_string_literal: true

class AddUpdateNamespaceNameToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '16.6'

  def change
    add_column :application_settings, :update_namespace_name_rate_limit, :smallint, default: 120, null: false
  end
end
