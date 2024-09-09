# frozen_string_literal: true

class AddOrganizationIdAndNameIndexOnTopics < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  disable_ddl_transaction!

  OLD_INDEX = 'index_topics_on_name'
  NEW_INDEX = 'index_topics_on_organization_id_and_name'

  # Replaces the current schema index: CREATE UNIQUE INDEX index_topics_on_name ON topics USING btree (name);
  def up
    add_concurrent_index :topics, [:organization_id, :name], name: NEW_INDEX, unique: true

    remove_concurrent_index_by_name :topics, name: OLD_INDEX
  end

  def down
    add_concurrent_index :topics, :name, name: OLD_INDEX, unique: true

    remove_concurrent_index_by_name :topics, name: NEW_INDEX
  end
end
