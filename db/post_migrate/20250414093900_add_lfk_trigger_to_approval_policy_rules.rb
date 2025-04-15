# frozen_string_literal: true

class AddLfkTriggerToApprovalPolicyRules < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '18.0'

  def up
    track_record_deletions(:approval_policy_rules)
  end

  def down
    untrack_record_deletions(:approval_policy_rules)
  end
end
