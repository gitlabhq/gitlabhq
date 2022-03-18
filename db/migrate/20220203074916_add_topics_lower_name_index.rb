# frozen_string_literal: true

class AddTopicsLowerNameIndex < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_topics_on_lower_name'

  disable_ddl_transaction!

  def up
    add_concurrent_index :topics, 'lower(name)', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :topics, INDEX_NAME
  end
end
