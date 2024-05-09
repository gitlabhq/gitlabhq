# frozen_string_literal: true

class CreateAiVectorizableFiles < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.0'

  def up
    create_table :ai_vectorizable_files do |t|
      t.timestamps_with_timezone null: false
      t.references :project, foreign_key: { on_delete: :cascade }, index: true, null: false
      t.text :name, null: false, limit: 255
      t.text :file, null: false, limit: 255
    end
  end

  def down
    drop_table :ai_vectorizable_files
  end
end
