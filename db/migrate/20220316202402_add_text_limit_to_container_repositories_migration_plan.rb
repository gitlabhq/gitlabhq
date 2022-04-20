# frozen_string_literal: true

class AddTextLimitToContainerRepositoriesMigrationPlan < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit :container_repositories, :migration_plan, 255
  end

  def down
    remove_text_limit :container_repositories, :migration_plan
  end
end
