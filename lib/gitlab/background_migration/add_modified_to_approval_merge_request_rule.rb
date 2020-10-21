# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Compare all current rules to project rules
    class AddModifiedToApprovalMergeRequestRule
      # Stubbed class to access the Group table
      class Group < ActiveRecord::Base
        self.table_name = 'namespaces'
        self.inheritance_column = :_type_disabled
      end

      # Stubbed class to access the ApprovalMergeRequestRule table
      class ApprovalMergeRequestRule < ActiveRecord::Base
        self.table_name = 'approval_merge_request_rules'

        has_one :approval_merge_request_rule_source, class_name: 'AddModifiedToApprovalMergeRequestRule::ApprovalMergeRequestRuleSource'
        has_one :approval_project_rule, through: :approval_merge_request_rule_source
        has_and_belongs_to_many :groups,
          class_name: 'AddModifiedToApprovalMergeRequestRule::Group', join_table: "#{self.table_name}_groups"
      end

      # Stubbed class to access the ApprovalProjectRule table
      class ApprovalProjectRule < ActiveRecord::Base
        self.table_name = 'approval_project_rules'

        has_many :approval_merge_request_rule_sources, class_name: 'AddModifiedToApprovalMergeRequestRule::ApprovalMergeRequestRuleSource'
        has_and_belongs_to_many :groups,
          class_name: 'AddModifiedToApprovalMergeRequestRule::Group', join_table: "#{self.table_name}_groups"
      end

      # Stubbed class to access the ApprovalMergeRequestRuleSource table
      class ApprovalMergeRequestRuleSource < ActiveRecord::Base
        self.table_name = 'approval_merge_request_rule_sources'

        belongs_to :approval_merge_request_rule, class_name: 'AddModifiedToApprovalMergeRequestRule::ApprovalMergeRequestRule'
        belongs_to :approval_project_rule, class_name: 'AddModifiedToApprovalMergeRequestRule::ApprovalProjectRule'
      end

      def perform(start_id, stop_id)
        approval_merge_requests_rules = ApprovalMergeRequestRule
          .joins(:groups, :approval_merge_request_rule_source)
          .where(id: start_id..stop_id)
          .pluck(
            'approval_merge_request_rule_sources.id as ars_id',
            'approval_merge_request_rules_groups.id as amrg_id'
          )

        approval_project_rules = ApprovalProjectRule
          .joins(:groups, approval_merge_request_rule_sources: :approval_merge_request_rule)
          .where(approval_merge_request_rules: { id: start_id..stop_id })
          .pluck(
            'approval_merge_request_rule_sources.id as ars_id',
            'approval_project_rules_groups.id as apg_id'
          )

        different_names_or_approval_sources = ApprovalMergeRequestRule.joins(:approval_project_rule, :approval_merge_request_rule_source)
          .where(id: start_id..stop_id)
          .where('approval_merge_request_rules.name != approval_project_rules.name OR ' \
                'approval_merge_request_rules.approvals_required != approval_project_rules.approvals_required')
          .pluck('approval_merge_request_rule_sources.id as ars_id')

        intersected_set = approval_merge_requests_rules.to_set ^ approval_project_rules.to_set
        source_ids = intersected_set.collect { |rule| rule[0] }.uniq

        rule_sources = ApprovalMergeRequestRuleSource.where(id: source_ids + different_names_or_approval_sources)
        changed_merge_request_rules = ApprovalMergeRequestRule.where(id: rule_sources.select(:approval_merge_request_rule_id))

        changed_merge_request_rules.update_all(modified_from_project_rule: true)
      end
    end
  end
end
