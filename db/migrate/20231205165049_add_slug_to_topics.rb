# frozen_string_literal: true

class AddSlugToTopics < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.8'

  def up
    with_lock_retries do
      add_column :topics, :slug, :text, if_not_exists: true
    end

    add_text_limit :topics, :slug, 255
  end

  def down
    with_lock_retries do
      remove_column :topics, :slug, if_exists: true
    end
  end
end
