# frozen_string_literal: true

class ValidateNotNullConstraintOnPushRulesProjectId < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!

  def up
    # Only validate on GitLab.com. The DeleteNullProjectIdPushRules BBM has been
    # finalized for GitLab.com, so there are no NULL project_id rows to violate
    # the constraint. On self-managed the BBM is not finalized yet, so
    # validating would fail.
    #
    # Finalization for self-managed will be handled by
    # https://gitlab.com/gitlab-org/gitlab/-/issues/607954
    # and validation on self-managed will be handled by
    # https://gitlab.com/gitlab-org/gitlab/-/issues/607955
    return unless Gitlab.com_except_jh?

    validate_not_null_constraint :push_rules, :project_id
  end

  def down
    # no-op
  end
end
