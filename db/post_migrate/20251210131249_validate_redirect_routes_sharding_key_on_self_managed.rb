# frozen_string_literal: true

class ValidateRedirectRoutesShardingKeyOnSelfManaged < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  CONSTRAINT_NAME = :check_e82ff70482

  def up
    # NOTE: this is a follow up to https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215320/diffs
    return if Gitlab.com_except_jh?

    validate_not_null_constraint :redirect_routes, :namespace_id, constraint_name: CONSTRAINT_NAME
  end

  def down
    # no-op
  end
end
