# frozen_string_literal: true

class CreateNoteDuoMetadata < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.0'

  def up
    create_table :note_duo_metadata, id: false do |t|
      t.references :note,
        primary_key: true,
        index: false,
        foreign_key: { on_delete: :cascade }
      t.bigint :workflow_id, null: false
      t.bigint :namespace_id, null: false
      t.datetime_with_timezone :created_at
      t.datetime_with_timezone :updated_at
    end

    add_concurrent_index :note_duo_metadata, :namespace_id # FK
    add_concurrent_index :note_duo_metadata, :workflow_id # FK
    add_concurrent_index :note_duo_metadata, [:note_id, :workflow_id], # uniqueness validation
      unique: true,
      name: 'idx_note_duo_metadata_note_and_workflow'
  end

  def down
    drop_table :note_duo_metadata
  end
end
