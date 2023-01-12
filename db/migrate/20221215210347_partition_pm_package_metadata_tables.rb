# frozen_string_literal: true

class PartitionPmPackageMetadataTables < Gitlab::Database::Migration[2.1]
  def up
    # no-op
    # This migration was reverted as part of https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108644
    # The migration file is re-added to ensure that all environments have the same list of migrations.
  end

  def down
    # no-op
  end
end
