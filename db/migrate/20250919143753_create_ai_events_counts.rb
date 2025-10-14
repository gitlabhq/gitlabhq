# frozen_string_literal: true

class CreateAiEventsCounts < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.5'

  def change
    opts = {
      primary_key: [:id, :events_date],
      options: 'PARTITION BY RANGE (events_date)',
      if_not_exists: true
    }

    create_table :ai_events_counts, **opts do |t|
      t.bigserial :id, null: false
      t.date :events_date, null: false
      t.bigint :namespace_id
      t.belongs_to :user, null: false
      t.references :organization, foreign_key: { on_delete: :cascade }, null: false
      t.integer :event, limit: 2, null: false
      t.integer :total_occurrences, null: false, default: 0
    end

    add_index :ai_events_counts, [:events_date, :namespace_id, :event, :user_id],
      unique: true,
      include: [:total_occurrences],
      nulls_not_distinct: true,
      name: 'idx_ai_events_counts_unique_tuple'
  end
end
