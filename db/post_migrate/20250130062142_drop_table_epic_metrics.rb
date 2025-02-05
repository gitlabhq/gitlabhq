# frozen_string_literal: true

class DropTableEpicMetrics < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def up
    drop_table :epic_metrics, if_exists: true
  end

  def down
    create_table :epic_metrics do |t|
      t.references :epic, null: false,
        index: { name: 'index_epic_metrics' },
        foreign_key: false

      # rubocop:disable Migration/Datetime -- Needs to match old table before removal
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      # rubocop:enable Migration/Datetime
    end
  end
end
