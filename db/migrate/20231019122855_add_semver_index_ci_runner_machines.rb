# frozen_string_literal: true

class AddSemverIndexCiRunnerMachines < Gitlab::Database::Migration[2.1]
  MAJOR_INDEX_NAME = 'index_ci_runner_machines_on_major_version_trigram'
  MINOR_INDEX_NAME = 'index_ci_runner_machines_on_minor_version_trigram'
  PATCH_INDEX_NAME = 'index_ci_runner_machines_on_patch_version_trigram'

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_runner_machines, %q[((substring(version from '^\d+\.'))), version, runner_id],
      name: MAJOR_INDEX_NAME
    add_concurrent_index :ci_runner_machines, %q[((substring(version from '^\d+\.\d+\.'))), version, runner_id],
      name: MINOR_INDEX_NAME
    add_concurrent_index :ci_runner_machines, %q[((substring(version from '^\d+\.\d+\.\d+'))), version, runner_id],
      name: PATCH_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_runner_machines, MAJOR_INDEX_NAME
    remove_concurrent_index_by_name :ci_runner_machines, MINOR_INDEX_NAME
    remove_concurrent_index_by_name :ci_runner_machines, PATCH_INDEX_NAME
  end
end
