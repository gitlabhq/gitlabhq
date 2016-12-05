class AddJidToProjectImportData < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :project_import_data, :jid, :string
  end
end
