# frozen_string_literal: true

class CreatePartitionedMergeRequestDiffCommits < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.10'

  disable_ddl_transaction!

  def up
    # no-op: Previous migration attempt failed because function already exists
    # See: https://gitlab.com/gitlab-com/gl-infra/production/-/work_items/21519
  end

  def down
    # no-op
  end
end
