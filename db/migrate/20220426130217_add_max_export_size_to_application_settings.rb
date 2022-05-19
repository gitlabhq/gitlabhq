# frozen_string_literal: true

class AddMaxExportSizeToApplicationSettings < Gitlab::Database::Migration[2.0]
  def change
    add_column :application_settings, :max_export_size, :integer, default: 0
  end
end
