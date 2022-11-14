# frozen_string_literal: true

class AddDisableDownloadButtonIntoApplicationSettings < Gitlab::Database::Migration[2.0]
  def change
    add_column :application_settings, :disable_download_button, :boolean,
               null: false, default: false, comment: 'JiHu-specific column'
  end
end
