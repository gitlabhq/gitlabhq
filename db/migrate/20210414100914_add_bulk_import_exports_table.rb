# frozen_string_literal: true

class AddBulkImportExportsTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  def up
    create_table_with_constraints :bulk_import_exports do |t|
      t.bigint :group_id
      t.bigint :project_id
      t.timestamps_with_timezone null: false
      t.integer :status, limit: 2, null: false, default: 0
      t.text :relation, null: false
      t.text :jid, unique: true
      t.text :error

      t.text_limit :relation, 255
      t.text_limit :jid, 255
      t.text_limit :error, 255
    end
  end

  def down
    drop_table :bulk_import_exports
  end
end
