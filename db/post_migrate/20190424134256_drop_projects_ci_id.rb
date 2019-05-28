# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class DropProjectsCiId < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    if index_exists?(:projects, :ci_id)
      remove_concurrent_index :projects, :ci_id
    end

    if column_exists?(:projects, :ci_id)
      remove_column :projects, :ci_id
    end
  end

  def down
    unless column_exists?(:projects, :ci_id)
      add_column :projects, :ci_id, :integer
    end

    unless index_exists?(:projects, :ci_id)
      add_concurrent_index :projects, :ci_id
    end
  end
end
