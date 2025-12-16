# frozen_string_literal: true

class DeleteOrphanRedirectRoutesNamespaceRows < Gitlab::Database::Migration[2.3]
  milestone '18.7'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  disable_ddl_transaction!

  BATCH_SIZE = 1000

  def up
    # NOTE: No such rows exist on .com and the sharding key has already been validated.
    #       This query must be run for self-managed instances where the prior validation
    #       failed (https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215320/diffs).
    #       This is part of https://gitlab.com/gitlab-org/gitlab/-/issues/561339
    return if Gitlab.com_except_jh?

    define_batchable_model('redirect_routes')
      .where(source_type: 'Namespace', namespace_id: nil)
      .each_batch(of: BATCH_SIZE) do |batch|
      batch
        .joins('LEFT OUTER JOIN namespaces ON redirect_routes.source_id = namespaces.id')
        .where(namespaces: { id: nil })
        .delete_all
    end
  end

  def down
    # no-op
  end
end
