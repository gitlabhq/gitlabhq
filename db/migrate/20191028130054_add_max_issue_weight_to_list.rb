# frozen_string_literal: true

class AddMaxIssueWeightToList < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_column_with_default :lists, :max_issue_weight, :integer, default: 0
  end

  def down
    remove_column :lists, :max_issue_weight
  end
end
