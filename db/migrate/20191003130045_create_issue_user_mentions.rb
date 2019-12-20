# frozen_string_literal: true

class CreateIssueUserMentions < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :issue_user_mentions do |t|
      t.references :issue, type: :integer, index: false, null: false, foreign_key: { on_delete: :cascade }
      t.references :note, type: :integer,
                   index: { where: 'note_id IS NOT NULL', unique: true }, null: true, foreign_key: { on_delete: :cascade }
      t.integer    :mentioned_users_ids, array: true
      t.integer    :mentioned_projects_ids, array: true
      t.integer    :mentioned_groups_ids, array: true
    end

    add_index :issue_user_mentions, [:issue_id], where: 'note_id is null', unique: true, name: 'issue_user_mentions_on_issue_id_index'
    add_index :issue_user_mentions, [:issue_id, :note_id], unique: true, name: 'issue_user_mentions_on_issue_id_and_note_id_index'
  end
end
