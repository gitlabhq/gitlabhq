# frozen_string_literal: true

class AddOrganizationIdAndSlugIndexOnTopics < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  disable_ddl_transaction!

  OLD_INDEX = 'index_topics_on_slug'
  NEW_INDEX = 'index_topics_on_organization_id_slug_and'

  def up
    add_concurrent_index(
      :topics,
      [:organization_id, :slug],
      name: NEW_INDEX,
      unique: true,
      where: '(slug IS NOT NULL)'
    )

    remove_concurrent_index_by_name :topics, name: OLD_INDEX
  end

  def down
    add_concurrent_index :topics, :slug, name: OLD_INDEX, unique: true, where: '(slug IS NOT NULL)'

    remove_concurrent_index_by_name :topics, name: NEW_INDEX
  end
end
