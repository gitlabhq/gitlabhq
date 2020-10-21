# frozen_string_literal: true

class CreateBulkImportConfigurations < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :bulk_import_configurations, if_not_exists: true do |t|
      t.references :bulk_import, type: :integer, index: true, null: false, foreign_key: { on_delete: :cascade }

      t.text :encrypted_url # rubocop: disable Migration/AddLimitToTextColumns
      t.text :encrypted_url_iv # rubocop: disable Migration/AddLimitToTextColumns

      t.text :encrypted_access_token # rubocop: disable Migration/AddLimitToTextColumns
      t.text :encrypted_access_token_iv # rubocop: disable Migration/AddLimitToTextColumns

      t.timestamps_with_timezone
    end
  end

  def down
    drop_table :bulk_import_configurations
  end
end
