# frozen_string_literal: true

class AddFksToMergeRequestsMergeData < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.4'

  TABLE_NAME = :merge_requests_merge_data

  def up
    # no-op to fix https://gitlab.com/gitlab-com/gl-infra/production/-/issues/20468
  end

  def down
    # no-op to fix https://gitlab.com/gitlab-com/gl-infra/production/-/issues/20468
  end
end
