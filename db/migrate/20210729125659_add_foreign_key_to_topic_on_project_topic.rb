# frozen_string_literal: true

class AddForeignKeyToTopicOnProjectTopic < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :project_topics, :topics, column: :topic_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :project_topics, column: :topic_id
    end
  end
end
