# frozen_string_literal: true

class AddSectionAndCreatedAtCodeownerApprovalMergeRequestIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  SECTION_CREATED_AT_ON_CODEOWNER_APPROVAL_MERGE_REQUEST_RULES = "index_created_at_on_codeowner_approval_merge_request_rules"
  RULE_TYPE_CODEOWNERS = 2
  CODEOWNER_SECTION_DEFAULT = 'codeowners'

  disable_ddl_transaction!

  def up
    add_concurrent_index :approval_merge_request_rules, :created_at,
      where: "rule_type = #{RULE_TYPE_CODEOWNERS} AND section != '#{CODEOWNER_SECTION_DEFAULT}'::text",
      name: SECTION_CREATED_AT_ON_CODEOWNER_APPROVAL_MERGE_REQUEST_RULES
  end

  def down
    remove_concurrent_index_by_name :approval_merge_request_rules, SECTION_CREATED_AT_ON_CODEOWNER_APPROVAL_MERGE_REQUEST_RULES
  end
end
