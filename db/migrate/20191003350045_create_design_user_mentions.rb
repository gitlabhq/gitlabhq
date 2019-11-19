# frozen_string_literal: true

class CreateDesignUserMentions < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :design_user_mentions do |t|
      t.references :design, type: :integer, index: false, null: false,
                   foreign_key: { to_table: :design_management_designs, column: :design_id, on_delete: :cascade }
      t.references :note, type: :integer,
                   index: { unique: true }, null: false, foreign_key: { on_delete: :cascade }
      t.integer    :mentioned_users_ids, array: true
      t.integer    :mentioned_projects_ids, array: true
      t.integer    :mentioned_groups_ids, array: true
    end

    add_index :design_user_mentions, [:design_id, :note_id], name: 'design_user_mentions_on_design_id_and_note_id_index'
  end
end
