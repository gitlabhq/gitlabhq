# frozen_string_literal: true

class AlterVsaIssueFirstMentionedInCommitValue < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  ISSUE_FIRST_MENTIONED_IN_COMMIT_FOSS = 2
  ISSUE_FIRST_MENTIONED_IN_COMMIT_EE = 6

  class GroupStage < ActiveRecord::Base
    self.table_name = 'analytics_cycle_analytics_group_stages'

    include EachBatch
  end

  def up
    GroupStage.each_batch(of: 100) do |relation|
      relation
        .where(start_event_identifier: ISSUE_FIRST_MENTIONED_IN_COMMIT_EE)
        .update_all(start_event_identifier: ISSUE_FIRST_MENTIONED_IN_COMMIT_FOSS)

      relation
        .where(end_event_identifier: ISSUE_FIRST_MENTIONED_IN_COMMIT_EE)
        .update_all(end_event_identifier: ISSUE_FIRST_MENTIONED_IN_COMMIT_FOSS)
    end
  end

  def down
    # rollback is not needed, the identifier "6" is the same as identifier "2" on the application level
  end
end
