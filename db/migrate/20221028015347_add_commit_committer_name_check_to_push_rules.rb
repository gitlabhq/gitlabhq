# frozen_string_literal: true

class AddCommitCommitterNameCheckToPushRules < Gitlab::Database::Migration[2.0]
  def change
    add_column :push_rules, :commit_committer_name_check, :boolean, default: false, null: false
  end
end
