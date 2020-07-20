# frozen_string_literal: true

class CreateSnippetStatistics < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      create_table :snippet_statistics, id: false do |t|
        t.references :snippet, primary_key: true, default: nil, index: false, foreign_key: { on_delete: :cascade }
        t.bigint :repository_size, default: 0, null: false
        t.bigint :file_count, default: 0, null: false
        t.bigint :commit_count, default: 0, null: false
      end
    end
  end

  def down
    with_lock_retries do
      drop_table :snippet_statistics
    end
  end
end
