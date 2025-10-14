# frozen_string_literal: true

class UpdateNilDesiredConfigGeneratorVersionWorkspace < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '18.5'

  def up
    workspaces = define_batchable_model('workspaces')

    workspaces
      .where(desired_config_generator_version: nil)
      .each_batch(of: 50) do |batch|
      batch.update_all(desired_config_generator_version: 3)
    end
  end

  def down
    # no-op
  end
end
