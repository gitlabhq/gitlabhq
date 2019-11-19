# frozen_string_literal: true

class CreateEpicUserMentions < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :epic_user_mentions do |t|
      t.references :epic, type: :integer, index: false, null: false, foreign_key: { on_delete: :cascade }
      t.references :note, type: :integer,
                   index: { where: 'note_id IS NOT NULL', unique: true }, null: true, foreign_key: { on_delete: :cascade }
      t.integer    :mentioned_users_ids, array: true
      t.integer    :mentioned_projects_ids, array: true
      t.integer    :mentioned_groups_ids, array: true
    end

    add_index :epic_user_mentions, [:epic_id], where: 'note_id is null', unique: true, name: 'epic_user_mentions_on_epic_id_index'
    add_index :epic_user_mentions, [:epic_id, :note_id], unique: true, name: 'epic_user_mentions_on_epic_id_and_note_id_index'
  end
end
