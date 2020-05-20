# frozen_string_literal: true

class AddProjectsForeignKeyToNamespaces < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  FK_NAME = 'fk_projects_namespace_id'

  def up
    with_lock_retries do
      add_foreign_key(
        :projects,
        :namespaces,
        column: :namespace_id,
        on_delete: :restrict,
        validate: false,
        name: FK_NAME
      )
    end
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :projects, column: :namespace_id, name: FK_NAME
    end
  end
end
