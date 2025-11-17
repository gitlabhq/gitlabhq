# frozen_string_literal: true

class CreateCustomDashboardVersions < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.6'

  # rubocop:disable Migration/EnsureFactoryForTable -- No factory needed
  def up
    create_table :custom_dashboard_versions, if_not_exists: true do |t|
      t.references :custom_dashboard, null: false, index: false, foreign_key: true
      t.integer :version_number, null: false
      t.jsonb :config, null: false, default: {}
      t.bigint :updated_by_id
      t.timestamps_with_timezone null: false

      t.index [:custom_dashboard_id, :version_number],
        unique: true,
        name: 'index_dashboard_versions_on_dashboard_and_version'

      t.index :created_at
    end

    add_check_constraint(
      :custom_dashboard_versions,
      "(jsonb_typeof(config) = 'object')",
      "chk_dashboard_versions_config_object"
    )
  end
  # rubocop:enable Migration/EnsureFactoryForTable

  def down
    drop_table :custom_dashboard_versions
  end
end
