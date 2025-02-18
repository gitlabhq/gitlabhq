# frozen_string_literal: true

class ValidateApprovalMergeRequestRuleSourcesProjectIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def up
    validate_not_null_constraint :approval_merge_request_rule_sources, :project_id
  end

  def down
    # no-op
  end
end
