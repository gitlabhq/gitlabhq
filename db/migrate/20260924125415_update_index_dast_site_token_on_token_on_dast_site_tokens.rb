# frozen_string_literal: true

class UpdateIndexDastSiteTokenOnTokenOnDastSiteTokens < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.5'

  TABLE_NAME = :dast_site_tokens
  NEW_INDEX_NAME = :index_dast_site_token_on_token_and_project_id
  OLD_INDEX_NAME = :index_dast_site_token_on_token

  def up
    add_concurrent_index(
      TABLE_NAME,
      %i[token project_id],
      unique: true,
      name: NEW_INDEX_NAME
    )

    remove_concurrent_index_by_name(TABLE_NAME, OLD_INDEX_NAME)
  end

  # Rollback re-adds global uniqueness on token and fails if the same token exists
  # in more than one project. Not expected, because tokens are server-generated.
  def down
    add_concurrent_index(
      TABLE_NAME,
      %i[token],
      unique: true,
      name: OLD_INDEX_NAME
    )

    remove_concurrent_index_by_name(TABLE_NAME, NEW_INDEX_NAME)
  end
end
