# frozen_string_literal: true

class CreateBulkImport < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      create_table :bulk_imports do |t|
        t.references :user, type: :integer, index: true, null: false, foreign_key: { on_delete: :cascade }

        t.integer :source_type, null: false, limit: 2
        t.integer :status, null: false, limit: 2

        t.timestamps_with_timezone
      end
    end
  end

  def down
    with_lock_retries do
      drop_table :bulk_imports
    end
  end
end
