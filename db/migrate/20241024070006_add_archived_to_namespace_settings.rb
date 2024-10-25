# frozen_string_literal: true

class AddArchivedToNamespaceSettings < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def change
    add_column :namespace_settings, :archived, :boolean, default: false, null: false
  end
end
