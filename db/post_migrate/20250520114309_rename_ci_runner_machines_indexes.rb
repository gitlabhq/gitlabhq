# frozen_string_literal: true

class RenameCiRunnerMachinesIndexes < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  INDEXES = [
    %w[index_ci_runner_machines_on_major_version_trigram index_ci_runner_machines_on_major_version],
    %w[index_ci_runner_machines_on_minor_version_trigram index_ci_runner_machines_on_minor_version],
    %w[index_ci_runner_machines_on_patch_version_trigram index_ci_runner_machines_on_patch_version]
  ]

  def up
    INDEXES.each do |old_name, new_name|
      execute "ALTER INDEX IF EXISTS #{old_name} RENAME TO #{new_name}"
    end
  end

  def down
    INDEXES.each do |old_name, new_name|
      execute "ALTER INDEX IF EXISTS #{new_name} RENAME TO #{old_name}"
    end
  end
end
