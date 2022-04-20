# frozen_string_literal: true

class AddMigrationPlanToContainerRepositories < Gitlab::Database::Migration[1.0]
  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20220316202402_add_text_limit_to_container_repositories_migration_plan
  def change
    add_column(:container_repositories, :migration_plan, :text)
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
