# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class PopulateRuleTypeOnApprovalMergeRequestRules < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  class ApprovalMergeRequestRule < ActiveRecord::Base
    include EachBatch

    enum rule_types: {
      regular: 1,
      code_owner: 2
    }
  end

  def up
    # On Gitlab.com, this should update about 17k rows. Since our updates are
    # small and we are populating prior to indexing, the overhead should be small
    ApprovalMergeRequestRule.where(code_owner: true).each_batch do |batch|
      batch.update_all(rule_type: ApprovalMergeRequestRule.rule_types[:code_owner])
    end
  end

  def down
    # code_owner is already kept in sync with `rule_type`, so no changes are needed
  end
end
