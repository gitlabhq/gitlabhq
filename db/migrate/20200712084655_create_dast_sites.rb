# frozen_string_literal: true

class CreateDastSites < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      create_table :dast_sites do |t|
        t.references :project, foreign_key: { on_delete: :cascade }, null: false, index: false
        t.timestamps_with_timezone null: false

        t.text :url, null: false
      end
    end

    add_concurrent_index :dast_sites, [:project_id, :url], unique: true
    add_text_limit :dast_sites, :url, 255
  end

  def down
    drop_table :dast_sites
  end
end
