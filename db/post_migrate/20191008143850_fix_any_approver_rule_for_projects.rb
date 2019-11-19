# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class FixAnyApproverRuleForProjects < ActiveRecord::Migration[5.2]
  DOWNTIME = false
  BATCH_SIZE = 1000

  disable_ddl_transaction!

  class ApprovalProjectRule < ActiveRecord::Base
    NON_EXISTENT_RULE_TYPE = 4
    ANY_APPROVER_RULE_TYPE = 3

    include EachBatch

    self.table_name = 'approval_project_rules'

    scope :any_approver, -> { where(rule_type: ANY_APPROVER_RULE_TYPE) }
    scope :non_existent_rule_type, -> { where(rule_type: NON_EXISTENT_RULE_TYPE) }
  end

  def up
    return unless Gitlab.ee?

    # Remove approval project rule with rule type 4 if the project has a rule with rule_type 3
    #
    # Currently, there is no projects on gitlab.com which have both rules with 3 and 4 rule type
    # There's a code-level validation for a rule, which doesn't allow to create rules with the same names
    #
    # But in order to avoid failing the update query due to uniqueness constraint
    # Let's run the delete query to be sure
    project_ids = FixAnyApproverRuleForProjects::ApprovalProjectRule.any_approver.select(:project_id)
    FixAnyApproverRuleForProjects::ApprovalProjectRule
      .non_existent_rule_type
      .where(project_id: project_ids)
      .delete_all

    # Set approval project rule types to 3
    # Currently there are 18_445 records to be updated
    FixAnyApproverRuleForProjects::ApprovalProjectRule.non_existent_rule_type.each_batch(of: BATCH_SIZE) do |rules|
      rules.update_all(rule_type: FixAnyApproverRuleForProjects::ApprovalProjectRule::ANY_APPROVER_RULE_TYPE)
    end
  end

  def down
    # The migration doesn't leave the database in an inconsistent state
    # And can be run multiple times
  end
end
