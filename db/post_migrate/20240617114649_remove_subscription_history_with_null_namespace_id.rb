# frozen_string_literal: true

class RemoveSubscriptionHistoryWithNullNamespaceId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.2'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  BATCH_SIZE = 10_000

  class GitlabSubscriptionHistory < MigrationRecord
    include EachBatch

    self.table_name = 'gitlab_subscription_histories'
  end

  def up
    GitlabSubscriptionHistory.each_batch(of: BATCH_SIZE) do |batch|
      batch.where(namespace_id: nil).delete_all
    end
  end

  def down
    # no-op
  end
end
