# frozen_string_literal: true

class AddPurlSyncToSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :package_metadata_purl_types, :smallint, array: true, default: []
  end
end
