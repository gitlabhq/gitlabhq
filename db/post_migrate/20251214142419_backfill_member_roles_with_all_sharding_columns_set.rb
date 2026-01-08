# frozen_string_literal: true

class BackfillMemberRolesWithAllShardingColumnsSet < Gitlab::Database::Migration[2.3]
  milestone '18.8'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  disable_ddl_transaction!

  BATCH_SIZE = 1000

  def up
    # NOTE: this backfill is the complement of https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207050/diffs#diff-content-accdb3fb59590ca59111b06415848ba49ee84e85
    #       As the other migration set a sharding key column for rows that
    #       had all sharding key columns set to NULL, this migration will
    #       address rows where all (both) sharding key columns are set.
    define_batchable_model('member_roles')
      .where.not(organization_id: nil)
      .where.not(namespace_id: nil)
      .each_batch(of: BATCH_SIZE) do |batch|
      batch.update_all(organization_id: nil)
    end
  end

  def down
    # no-op
  end
end
