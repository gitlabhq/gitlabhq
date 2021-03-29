# frozen_string_literal: true

class CreateAdminNotes < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    create_table_with_constraints :namespace_admin_notes do |t|
      t.timestamps_with_timezone
      t.references :namespace, null: false, foreign_key: { on_delete: :cascade }
      t.text :note

      t.text_limit :note, 1000
    end
  end

  def down
    drop_table :namespace_admin_notes
  end
end
