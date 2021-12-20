# frozen_string_literal: true

class DropPagesDeploymentsBuildsFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  FK_NAME = 'fk_rails_c3a90cf29b'

  def up
    remove_foreign_key_if_exists(:pages_deployments, :ci_builds, name: FK_NAME)
  end

  def down
    add_concurrent_foreign_key(
      :pages_deployments,
      :ci_builds,
      name: FK_NAME,
      column: :ci_build_id,
      target_column: :id,
      on_delete: :nullify
    )
  end
end
