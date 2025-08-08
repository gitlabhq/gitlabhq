# frozen_string_literal: true

class AddNotNullToDeployTokensShardingKeys < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  def up
    # No-op: This migration created constraint violations on staging, see https://gitlab.com/gitlab-com/gl-infra/production/-/issues/20317
  end

  def down
    # No op
  end
end
