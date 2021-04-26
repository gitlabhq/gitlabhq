# frozen_string_literal: true

class CleanupGitlabSubscriptionsWithNullNamespaceId < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  class GitlabSubscription < ActiveRecord::Base
    self.table_name = 'gitlab_subscriptions'
  end

  def up
    # As of today, there is 0 records whose namespace_id is null on GitLab.com.
    # And we expect no such records on non GitLab.com instance.
    # So this post-migration cleanup script is just for extra safe.
    #
    # This will be fast on GitLab.com, because:
    #   - gitlab_subscriptions.count=5021850
    #   - namespace_id is indexed, so the query is pretty fast. Try on database-lab, this uses 5.931 ms
    GitlabSubscription.where(namespace_id: nil).delete_all
  end

  def down
    # no-op : can't go back to `NULL` without first dropping the `NOT NULL` constraint
  end
end
