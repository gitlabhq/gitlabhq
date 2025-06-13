# frozen_string_literal: true

module Gitlab
  module ApprovalRules
    module V2
      class DataMapper
        def initialize(v1_rule)
          @v1_rule = v1_rule
        end

        def migrate
          return unless v1_rule
          return unless Feature.enabled?(:v2_approval_rules, v1_rule.project)
          return unless merge_request_level_rule?

          ApplicationRecord.transaction do
            v2_rule = create_v2_rule
            create_merge_request_association(v2_rule)
            migrate_user_associations(v2_rule)
            v2_rule
          end
        end

        private

        attr_reader :v1_rule

        def merge_request_level_rule?
          v1_rule.is_a?(::ApprovalMergeRequestRule)
        end

        def create_v2_rule
          ::MergeRequests::ApprovalRule.create!(
            name: v1_rule.name,
            approvals_required: v1_rule.approvals_required,
            rule_type: v1_rule.rule_type,
            origin: :merge_request,
            project_id: v1_rule.project.id
          )
        end

        def create_merge_request_association(v2_rule)
          ::MergeRequests::ApprovalRulesMergeRequest.create!(
            approval_rule: v2_rule,
            merge_request: v1_rule.merge_request
          )
        end

        def migrate_user_associations(v2_rule)
          v1_rule.users.find_each do |user|
            ::MergeRequests::ApprovalRulesApproverUser.create!(
              approval_rule: v2_rule,
              user: user
            )
          end
        end
      end
    end
  end
end
