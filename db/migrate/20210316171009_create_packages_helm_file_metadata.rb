# frozen_string_literal: true

class CreatePackagesHelmFileMetadata < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    create_table_with_constraints :packages_helm_file_metadata, id: false do |t|
      t.timestamps_with_timezone
      t.references :package_file, primary_key: true, index: false, default: nil, null: false, foreign_key: { to_table: :packages_package_files, on_delete: :cascade }, type: :bigint
      t.text :channel, null: false
      t.jsonb :metadata

      t.text_limit :channel, 63

      t.index :channel
    end
  end

  def down
    with_lock_retries do
      drop_table :packages_helm_file_metadata
    end
  end
end
