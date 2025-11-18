# frozen_string_literal: true

class CreateCustomDashboardSearchData < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!

  # rubocop:disable Migration/EnsureFactoryForTable -- Search data table is derived, not a primary entity
  def up
    create_table :custom_dashboard_search_data, if_not_exists: true do |t|
      t.bigint :custom_dashboard_id, null: false
      t.text :name, null: false, default: '', limit: 255
      t.text :description, null: false, default: '', limit: 2048
      t.tsvector :search_vector, null: true
      t.timestamps_with_timezone null: false
    end

    add_concurrent_index :custom_dashboard_search_data, :search_vector,
      using: :gin,
      name: 'index_custom_dashboard_search_data_on_search_vector_gin'
    add_concurrent_index :custom_dashboard_search_data, :custom_dashboard_id, unique: true
    add_concurrent_foreign_key :custom_dashboard_search_data, :custom_dashboards,
      column: :custom_dashboard_id,
      on_delete: :cascade
  end
  # rubocop: enable Migration/EnsureFactoryForTable

  def down
    drop_table :custom_dashboard_search_data
  end
end
