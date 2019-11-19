# frozen_string_literal: true

class CreateCommitUserMentions < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :commit_user_mentions do |t|
      t.references :note, type: :integer,
                   index: { unique: true }, null: false, foreign_key: { on_delete: :cascade }
      t.binary     :commit_id, null: false
      t.integer    :mentioned_users_ids, array: true
      t.integer    :mentioned_projects_ids, array: true
      t.integer    :mentioned_groups_ids, array: true
    end

    add_index :commit_user_mentions, [:commit_id, :note_id], name: 'commit_user_mentions_on_commit_id_and_note_id_index'
  end
end
