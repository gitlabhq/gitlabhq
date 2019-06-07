# frozen_string_literal: true

class CreateMergeRequestAssigneesTable < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  INDEX_NAME = 'index_merge_request_assignees_on_merge_request_id_and_user_id'

  def up
    create_table :merge_request_assignees do |t|
      t.references :user, foreign_key: { on_delete: :cascade }, index: true, null: false
      t.references :merge_request, foreign_key: { on_delete: :cascade }, null: false
    end

    add_index :merge_request_assignees, [:merge_request_id, :user_id], unique: true, name: INDEX_NAME
  end

  def down
    drop_table :merge_request_assignees
  end
end
