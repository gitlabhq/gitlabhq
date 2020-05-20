# frozen_string_literal: true

class AddMaxIssueCountToList < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_column_with_default :lists, :max_issue_count, :integer, default: 0 # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column :lists, :max_issue_count
  end
end
