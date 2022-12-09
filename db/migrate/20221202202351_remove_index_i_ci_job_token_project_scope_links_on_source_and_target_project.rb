# frozen_string_literal: true
class RemoveIndexICiJobTokenProjectScopeLinksOnSourceAndTargetProject < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  TABLE_NAME = 'ci_job_token_project_scope_links'
  OLD_INDEX_NAME = 'i_ci_job_token_project_scope_links_on_source_and_target_project'
  NEW_INDEX_NAME = 'ci_job_token_scope_links_source_and_target_project_direction'
  NEW_INDEX_COL = %w[source_project_id target_project_id direction]

  def up
    add_concurrent_index(
      TABLE_NAME,
      NEW_INDEX_COL,
      name: NEW_INDEX_NAME,
      unique: true
    )
    remove_concurrent_index_by_name(TABLE_NAME, OLD_INDEX_NAME)
  end

  def down
    # noop: as we can have duplicate records once the unique index is removed
  end
end
