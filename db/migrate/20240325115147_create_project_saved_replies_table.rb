# frozen_string_literal: true

class CreateProjectSavedRepliesTable < Gitlab::Database::Migration[2.2]
  enable_lock_retries!

  milestone '16.11'

  def change
    create_table :project_saved_replies do |t|
      t.references :project, foreign_key: true, index: true, on_delete: :cascade, null: false
      t.timestamps_with_timezone null: false
      t.text :name, null: false, limit: 255
      t.text :content, null: false, limit: 10000
    end
  end
end
