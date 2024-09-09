# frozen_string_literal: true

class AddSlugIndexOnTopics < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  disable_ddl_transaction!

  NAME_INDEX = 'index_topics_on_name'
  SLUG_INDEX = 'index_topics_on_slug'

  # Add temporary indexes to support old queries (without organization_id) for topics
  def up
    add_concurrent_index :topics, :name, name: NAME_INDEX
    add_concurrent_index :topics, :slug, name: SLUG_INDEX, where: '(slug IS NOT NULL)'
  end

  def down
    remove_concurrent_index_by_name :topics, name: NAME_INDEX
    remove_concurrent_index_by_name :topics, name: SLUG_INDEX
  end
end
