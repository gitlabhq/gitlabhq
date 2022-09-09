# frozen_string_literal: true

class AddColumnBranchFilterStrategyToWebHooks < Gitlab::Database::Migration[2.0]
  def change
    add_column :web_hooks, :branch_filter_strategy, :integer, null: false, default: 0, limit: 2
  end
end
