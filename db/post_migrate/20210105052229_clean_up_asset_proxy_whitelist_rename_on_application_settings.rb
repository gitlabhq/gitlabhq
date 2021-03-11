# frozen_string_literal: true

class CleanUpAssetProxyWhitelistRenameOnApplicationSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers::V2

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # This migration has been made a no-op in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/56352
    # because to revert the rename in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/55419 we need
    # to cleanup the triggers on the `asset_proxy_allowlist` column. As such, this migration would do nothing.
  end

  def down
    # no-op
  end
end
