# frozen_string_literal: true
class CreateDraftNotes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :draft_notes, id: :bigserial do |t|
      t.references :merge_request, null: false, index: true, foreign_key: { on_delete: :cascade }
      t.foreign_key :users, null: false, column: :author_id, on_delete: :cascade
      t.integer :author_id, null: false, index: true
      t.boolean :resolve_discussion, default: false, null: false
      t.string :discussion_id
      t.text :note, null: false
      t.text :position
      t.text :original_position
      t.text :change_position
    end

    add_index :draft_notes, :discussion_id
  end
end
