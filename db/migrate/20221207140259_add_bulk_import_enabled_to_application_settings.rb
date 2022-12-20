# frozen_string_literal: true

class AddBulkImportEnabledToApplicationSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :bulk_import_enabled, :boolean, default: false, null: false
  end
end
