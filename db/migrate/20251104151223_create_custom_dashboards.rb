# frozen_string_literal: true

class CreateCustomDashboards < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.6'

  # rubocop:disable Migration/EnsureFactoryForTable -- To keep the MR small, factories would be added in following MR https://gitlab.com/gitlab-org/gitlab/-/merge_requests/211504
  def up
    create_table :custom_dashboards, if_not_exists: true do |t|
      t.bigint :namespace_id
      t.bigint :organization_id, null: false
      t.bigint :created_by_id
      t.bigint :updated_by_id
      t.integer :lock_version, null: false, default: 0
      t.text :name, null: false, limit: 255
      t.text :description, null: false, limit: 2048, default: ''
      t.jsonb :config, null: false, default: {}
      t.timestamps_with_timezone null: false

      t.index :namespace_id
      t.index :organization_id
      t.index :created_by_id
      t.index :updated_by_id
    end
    add_check_constraint(
      :custom_dashboards,
      "(jsonb_typeof(config) = 'object')",
      "chk_custom_dashboards_config_object"
    )
  end
  # rubocop: enable Migration/EnsureFactoryForTable

  def down
    drop_table :custom_dashboards
  end
end
