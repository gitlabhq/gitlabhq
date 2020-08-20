# frozen_string_literal: true

class CreateDastScannerProfile < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless table_exists?(:dast_scanner_profiles)
      with_lock_retries do
        create_table :dast_scanner_profiles do |t|
          t.timestamps_with_timezone null: false
          t.references :project, null: false, index: false, foreign_key: { on_delete: :cascade }, type: :integer
          t.integer :spider_timeout, limit: 2
          t.integer :target_timeout, limit: 2
          t.text :name, null: false
          t.index [:project_id, :name], unique: true
        end
      end
    end

    add_text_limit(:dast_scanner_profiles, :name, 255)
  end

  def down
    with_lock_retries do
      drop_table :dast_scanner_profiles
    end
  end
end
