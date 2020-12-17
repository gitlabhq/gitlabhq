# frozen_string_literal: true

class AddRunnerIdAndIdDescIndexToCiBuilds < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  NEW_INDEX = 'index_ci_builds_on_runner_id_and_id_desc'
  OLD_INDEX = 'index_ci_builds_on_runner_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_builds, %i[runner_id id], name: NEW_INDEX, order: { id: :desc }
    remove_concurrent_index_by_name :ci_builds, OLD_INDEX
  end

  def down
    add_concurrent_index :ci_builds, %i[runner_id], name: OLD_INDEX
    remove_concurrent_index_by_name :ci_builds, NEW_INDEX
  end
end
