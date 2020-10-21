# frozen_string_literal: true

class AddPagesDeploymentProjectForeignKey < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_foreign_key :pages_deployments, :projects, column: :project_id, on_delete: :cascade
    end
  end

  def down
    with_lock_retries do
      remove_foreign_key :pages_deployments, column: :project_id
    end
  end
end
