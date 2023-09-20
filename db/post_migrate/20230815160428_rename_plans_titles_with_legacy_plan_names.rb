# frozen_string_literal: true

class RenamePlansTitlesWithLegacyPlanNames < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_clusterwide

  def up
    execute "UPDATE plans SET title = 'Premium' WHERE name = 'premium'"
    execute "UPDATE plans SET title = 'Ultimate' WHERE name = 'ultimate'"
  end

  def down
    # no-op

    # We don't know or even want to revert back to the old plan titles.
  end
end
