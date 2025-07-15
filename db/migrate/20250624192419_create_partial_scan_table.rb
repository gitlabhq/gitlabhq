# frozen_string_literal: true

class CreatePartialScanTable < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  def change
    # rubocop:disable Migration/EnsureFactoryForTable -- Ruby namespace differs from table prefix
    create_table :vulnerability_partial_scans, id: false do |t|
      t.timestamps_with_timezone null: false
      t.bigint :scan_id, null: false, primary_key: true, index: true, default: nil
      t.bigint :project_id, null: false, index: true
      t.integer :mode, limit: 2, null: false
    end
    # rubocop:enable Migration/EnsureFactoryForTable
  end
end
