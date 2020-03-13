# frozen_string_literal: true

class CleanupEmptyCommitUserMentions < ActiveRecord::Migration[5.2]
  DOWNTIME = false
  BATCH_SIZE = 10_000

  class CommitUserMention < ActiveRecord::Base
    include EachBatch

    self.table_name = 'commit_user_mentions'
  end

  def up
    # cleanup commit user mentions with no actual mentions,
    # re https://gitlab.com/gitlab-org/gitlab/-/merge_requests/24586#note_285982468
    CommitUserMention
      .where(mentioned_users_ids: nil)
      .where(mentioned_groups_ids: nil)
      .where(mentioned_projects_ids: nil)
      .each_batch(of: BATCH_SIZE) do |batch|
      batch.delete_all
    end
  end

  def down
    # no-op
  end
end
