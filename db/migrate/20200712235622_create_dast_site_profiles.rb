# frozen_string_literal: true

class CreateDastSiteProfiles < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      create_table :dast_site_profiles do |t|
        t.references :project, foreign_key: { on_delete: :cascade }, null: false, index: false
        t.references :dast_site, foreign_key: { on_delete: :cascade }, null: false
        t.timestamps_with_timezone null: false

        t.text :name, null: false
      end
    end

    add_concurrent_index :dast_site_profiles, [:project_id, :name], unique: true
    add_text_limit :dast_site_profiles, :name, 255
  end

  def down
    drop_table :dast_site_profiles
  end
end
