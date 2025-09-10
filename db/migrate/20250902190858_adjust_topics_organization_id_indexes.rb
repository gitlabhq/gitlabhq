# frozen_string_literal: true

class AdjustTopicsOrganizationIdIndexes < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  disable_ddl_transaction!

  TABLE_NAME = :topics
  INDEX_ON_ORG_NAME_AND_PROJECT_COUNT = 'index_topics_on_org_id_and_lower_name_and_projects_count'
  INDEX_ON_SLUG = 'index_topics_on_slug'
  INDEX_ON_LOWER_NAME = 'index_topics_on_lower_name'

  def up
    add_concurrent_index(
      TABLE_NAME, 'organization_id, lower(name), total_projects_count DESC',
      name: INDEX_ON_ORG_NAME_AND_PROJECT_COUNT
    )

    remove_concurrent_index_by_name TABLE_NAME, INDEX_ON_SLUG
    remove_concurrent_index_by_name TABLE_NAME, INDEX_ON_LOWER_NAME
  end

  def down
    add_concurrent_index(TABLE_NAME, :slug, name: INDEX_ON_SLUG, where: 'slug IS NOT NULL')
    add_concurrent_index(TABLE_NAME, 'lower(name)', name: INDEX_ON_LOWER_NAME)
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_ON_ORG_NAME_AND_PROJECT_COUNT)
  end
end
