# frozen_string_literal: true

class AddRejectUnverifiedCommitsToGroupPushRules < Gitlab::Database::Migration[2.3]
  milestone '19.6'

  def change
    add_column :group_push_rules, :reject_unverified_commits, :boolean
  end
end
