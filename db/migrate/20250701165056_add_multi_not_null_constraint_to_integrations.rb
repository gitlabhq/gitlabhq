# frozen_string_literal: true

class AddMultiNotNullConstraintToIntegrations < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  disable_ddl_transaction!

  def up
    # No-op to fix https://gitlab.com/gitlab-com/gl-infra/production/-/issues/20126
  end

  def down
    # no-op to fix https://gitlab.com/gitlab-com/gl-infra/production/-/issues/20126
  end
end
