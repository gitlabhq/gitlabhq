# frozen_string_literal: true

class SetExistingPlanLimitsRepositorySizeToNull < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    execute "UPDATE plan_limits SET repository_size = NULL WHERE repository_size = 0"
  end

  def down
    execute "UPDATE plan_limits SET repository_size = 0 WHERE repository_size IS NULL"
  end
end
