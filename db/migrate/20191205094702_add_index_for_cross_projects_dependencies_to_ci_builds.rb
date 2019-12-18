# frozen_string_literal: true

class AddIndexForCrossProjectsDependenciesToCiBuilds < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_builds, [:project_id, :name, :ref],
      where: "type = 'Ci::Build' AND status = 'success' AND (retried = FALSE OR retried IS NULL)"
  end

  def down
    remove_concurrent_index :ci_builds, [:project_id, :name, :ref],
      where: "type = 'Ci::Build' AND status = 'success' AND (retried = FALSE OR retried IS NULL)"
  end
end
