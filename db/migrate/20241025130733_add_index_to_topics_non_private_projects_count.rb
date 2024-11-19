# frozen_string_literal: true

class AddIndexToTopicsNonPrivateProjectsCount < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  TABLE = :topics
  INDEX = 'index_topics_on_organization_id_and_non_private_projects_count'

  def up
    add_concurrent_index(
      TABLE,
      %i[organization_id non_private_projects_count],
      order: { non_private_projects_count: :desc },
      name: INDEX
    )
  end

  def down
    remove_concurrent_index_by_name TABLE, INDEX
  end
end
