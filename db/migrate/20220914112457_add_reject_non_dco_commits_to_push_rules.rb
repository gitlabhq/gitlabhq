# frozen_string_literal: true

class AddRejectNonDcoCommitsToPushRules < Gitlab::Database::Migration[2.0]
  def change
    add_column :push_rules, :reject_non_dco_commits, :boolean
  end
end
