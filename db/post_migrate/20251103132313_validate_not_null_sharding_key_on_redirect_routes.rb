# frozen_string_literal: true

class ValidateNotNullShardingKeyOnRedirectRoutes < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  CONSTRAINT_NAME = :check_e82ff70482

  def up
    # NOTE: this constraint validation caused issues on self-managed instances
    #       but ran successfully on .com (https://gitlab.com/gitlab-org/gitlab/-/work_items/581676)
    return unless Gitlab.com_except_jh?

    validate_not_null_constraint :redirect_routes, :namespace_id, constraint_name: CONSTRAINT_NAME
  end

  def down
    # no-op
  end
end
