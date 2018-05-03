class AddChecksumMismatchFieldsToProjectRegistry < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :project_registry, :repository_checksum_mismatch, :boolean, null: false, default: false
    add_column :project_registry, :wiki_checksum_mismatch, :boolean, null: false, default: false
  end
end
