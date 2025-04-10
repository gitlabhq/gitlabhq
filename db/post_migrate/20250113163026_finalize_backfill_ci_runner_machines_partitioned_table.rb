# frozen_string_literal: true

class FinalizeBackfillCiRunnerMachinesPartitionedTable < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    # no-op -- The BBM class no longer exists in the latest 17.8-17.10 patch releases
  end

  def down; end
end
