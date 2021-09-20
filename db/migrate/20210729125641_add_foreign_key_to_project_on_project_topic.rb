# frozen_string_literal: true

class AddForeignKeyToProjectOnProjectTopic < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :project_topics, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :project_topics, column: :project_id
    end
  end
end
