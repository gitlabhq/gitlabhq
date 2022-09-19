# frozen_string_literal: true

class AddTmpIndexApprovalMergeRequestRules < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  TMP_INDEX_NAME = 'tmp_index_approval_merge_request_rules_on_report_type_equal_one'

  def up
    # to be removed as part of https://gitlab.com/gitlab-org/gitlab/-/issues/372224
    add_concurrent_index :approval_merge_request_rules,
      [:id, :report_type],
      name: TMP_INDEX_NAME,
      where: "report_type = 1"
  end

  def down
    remove_concurrent_index_by_name :approval_merge_request_rules, TMP_INDEX_NAME
  end
end
