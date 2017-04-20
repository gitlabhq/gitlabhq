class AddImportJidToProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :projects, :import_jid, :string
  end
end
