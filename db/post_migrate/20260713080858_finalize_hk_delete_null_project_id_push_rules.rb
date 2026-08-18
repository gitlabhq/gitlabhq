# frozen_string_literal: true

class FinalizeHkDeleteNullProjectIdPushRules < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    # no-op: This migration already ran on GitLab.com. It was no-oped because
    # the DeleteNullProjectIdPushRules BBM has been requeued for self-managed
    # by RequeueDeleteNullProjectIdPushRules (20260805094315), so the BBM is
    # no longer finalized everywhere and `finalized_by` was cleared from the
    # dictionary. The self-managed finalization is tracked in
    # https://gitlab.com/gitlab-org/gitlab/-/work_items/607954
    # See https://gitlab.com/gitlab-org/gitlab/-/work_items/608164
  end

  def down
    # no-op
  end
end
