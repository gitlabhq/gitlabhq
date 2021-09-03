# frozen_string_literal: true

class AddProjectNamespaceIdToProject < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    with_lock_retries do
      # This is being added to Projects as a replacement for Namespace
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/337099
      add_column :projects, :project_namespace_id, :bigint # rubocop: disable Migration/AddColumnsToWideTables
    end
  end

  def down
    with_lock_retries do
      remove_column :projects, :project_namespace_id
    end
  end
end
