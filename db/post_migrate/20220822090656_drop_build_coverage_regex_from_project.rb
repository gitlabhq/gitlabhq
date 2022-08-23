# frozen_string_literal: true

class DropBuildCoverageRegexFromProject < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def up
    remove_column :projects, :build_coverage_regex
  end

  def down
    add_column :projects, :build_coverage_regex, :string # rubocop: disable Migration/AddColumnsToWideTables
  end
end
