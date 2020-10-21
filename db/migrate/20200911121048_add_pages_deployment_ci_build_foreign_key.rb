# frozen_string_literal: true

class AddPagesDeploymentCiBuildForeignKey < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_foreign_key :pages_deployments, :ci_builds, column: :ci_build_id, on_delete: :nullify
    end
  end

  def down
    with_lock_retries do
      remove_foreign_key :pages_deployments, column: :ci_build_id
    end
  end
end
