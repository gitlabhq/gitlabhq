# frozen_string_literal: true

class UpdateIndexApprovalRuleNameForCodeOwnersRuleType < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  LEGACY_INDEX_NAME_RULE_TYPE   = "index_approval_rule_name_for_code_owners_rule_type"
  LEGACY_INDEX_NAME_CODE_OWNERS = "approval_rule_name_index_for_code_owners"

  SECTIONAL_INDEX_NAME = "index_approval_rule_name_for_sectional_code_owners_rule_type"

  CODE_OWNER_RULE_TYPE = 2

  def up
    unless index_exists_by_name?(:approval_merge_request_rules, SECTIONAL_INDEX_NAME)
      # Ensure only 1 code_owner rule with the same name and section per merge_request
      #
      add_concurrent_index(
        :approval_merge_request_rules,
        [:merge_request_id, :name, :section],
        unique: true,
        where: "rule_type = #{CODE_OWNER_RULE_TYPE}",
        name: SECTIONAL_INDEX_NAME
      )
    end

    remove_concurrent_index_by_name :approval_merge_request_rules, LEGACY_INDEX_NAME_RULE_TYPE
    remove_concurrent_index_by_name :approval_merge_request_rules, LEGACY_INDEX_NAME_CODE_OWNERS

    add_concurrent_index(
      :approval_merge_request_rules,
      [:merge_request_id, :name],
      unique: true,
      where: "rule_type = #{CODE_OWNER_RULE_TYPE} AND section IS NULL",
      name: LEGACY_INDEX_NAME_RULE_TYPE
    )

    add_concurrent_index(
      :approval_merge_request_rules,
      [:merge_request_id, :code_owner, :name],
      unique: true,
      where: "code_owner = true AND section IS NULL",
      name: LEGACY_INDEX_NAME_CODE_OWNERS
    )
  end

  def down
    # In a rollback situation, we can't guarantee that there will not be
    #   records that were allowed under the more specific SECTIONAL_INDEX_NAME
    #   index but would cause uniqueness violations under both the
    #   LEGACY_INDEX_NAME_RULE_TYPE and LEGACY_INDEX_NAME_CODE_OWNERS indices.
    #   Therefore, we need to first find all the MergeRequests with
    #   ApprovalMergeRequestRules that would violate these "new" indices and
    #   delete those approval rules, then create the new index, then finally
    #   recreate the approval rules for those merge requests.
    #

    # First, find all MergeRequests with ApprovalMergeRequestRules that will
    #   violate the new index.
    #
    if Gitlab.ee?
      merge_request_ids = ApprovalMergeRequestRule
        .select(:merge_request_id)
        .where(rule_type: CODE_OWNER_RULE_TYPE)
        .group(:merge_request_id, :rule_type, :name)
        .includes(:merge_request)
        .having("count(*) > 1")
        .collect(&:merge_request_id)

      # Delete ALL their code_owner approval rules
      #
      merge_request_ids.each_slice(10) do |ids|
        ApprovalMergeRequestRule.where(merge_request_id: ids).code_owner.delete_all
      end
    end

    # Remove legacy partial indices that only apply to `section IS NULL` records
    #
    remove_concurrent_index_by_name :approval_merge_request_rules, LEGACY_INDEX_NAME_RULE_TYPE
    remove_concurrent_index_by_name :approval_merge_request_rules, LEGACY_INDEX_NAME_CODE_OWNERS

    # Reconstruct original "legacy" indices
    #
    add_concurrent_index(
      :approval_merge_request_rules,
      [:merge_request_id, :name],
      unique: true,
      where: "rule_type = #{CODE_OWNER_RULE_TYPE}",
      name: LEGACY_INDEX_NAME_RULE_TYPE
    )

    add_concurrent_index(
      :approval_merge_request_rules,
      [:merge_request_id, :code_owner, :name],
      unique: true,
      where: "code_owner = true",
      name: LEGACY_INDEX_NAME_CODE_OWNERS
    )

    # MergeRequest::SyncCodeOwnerApprovalRules recreates the code_owner rules
    #   from scratch, adding them to the index. Duplicates will be rejected.
    #
    if Gitlab.ee?
      merge_request_ids.each_slice(10) do |ids|
        MergeRequest.where(id: ids).each do |merge_request|
          MergeRequests::SyncCodeOwnerApprovalRules.new(merge_request).execute
        end
      end
    end

    remove_concurrent_index_by_name :approval_merge_request_rules, SECTIONAL_INDEX_NAME
  end
end
