# frozen_string_literal: true

class RemoveImportColumnsFromProjects < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    remove_column :projects, :import_status, :string
    remove_column :projects, :import_jid, :string
    remove_column :projects, :import_error, :text
  end
end
