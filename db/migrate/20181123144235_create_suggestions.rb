# frozen_string_literal: true

class CreateSuggestions < ActiveRecord::Migration[5.0]
  DOWNTIME = false

  def change
    create_table :suggestions, id: :bigserial do |t|
      t.references :note, foreign_key: { on_delete: :cascade }, null: false
      t.integer :relative_order, null: false, limit: 2
      t.boolean :applied, null: false, default: false
      t.string :commit_id # rubocop:disable Migration/AddLimitToStringColumns
      t.text :from_content, null: false
      t.text :to_content, null: false

      t.index [:note_id, :relative_order],
        name: 'index_suggestions_on_note_id_and_relative_order',
        unique: true
    end
  end
end
