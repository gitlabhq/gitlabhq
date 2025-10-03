# frozen_string_literal: true

class AddProjectsParentFkToMergeRequestsMergeData < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.5'

  def up
    # no-op due to https://gitlab.com/gitlab-com/gl-infra/production/-/issues/20659
  end

  def down
    # no-op due to https://gitlab.com/gitlab-com/gl-infra/production/-/issues/20659
  end
end
