# frozen_string_literal: true

class CreateSnippetRepositoryTable < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    create_table :snippet_repositories, id: false, primary_key: :snippet_id do |t|
      t.references :shard, null: false, index: true, foreign_key: { on_delete: :restrict }
      t.references :snippet, primary_key: true, default: nil, index: false, foreign_key: { on_delete: :cascade }
      t.string :disk_path, limit: 80, null: false, index: { unique: true }
    end
  end
  # rubocop:enable Migration/PreventStrings
end
