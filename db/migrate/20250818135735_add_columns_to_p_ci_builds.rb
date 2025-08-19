# frozen_string_literal: true

class AddColumnsToPCiBuilds < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  # rubocop:disable Migration/PreventAddingColumns -- adding them to new table will add overhead
  def up
    add_column :p_ci_builds, :scoped_user_id, :bigint, if_not_exists: true
    add_column :p_ci_builds, :timeout, :integer, if_not_exists: true
    add_column :p_ci_builds, :timeout_source, :integer, limit: 2, if_not_exists: true
    add_column :p_ci_builds, :exit_code, :integer, limit: 2, if_not_exists: true
    add_column :p_ci_builds, :debug_trace_enabled, :boolean, if_not_exists: true
  end

  def down
    remove_column :p_ci_builds, :scoped_user_id, if_exists: true
    remove_column :p_ci_builds, :timeout, if_exists: true
    remove_column :p_ci_builds, :timeout_source, if_exists: true
    remove_column :p_ci_builds, :exit_code, if_exists: true
    remove_column :p_ci_builds, :debug_trace_enabled, if_exists: true
  end
  # rubocop:enable Migration/PreventAddingColumns
end
