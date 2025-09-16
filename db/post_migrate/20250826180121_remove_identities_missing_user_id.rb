# frozen_string_literal: true

class RemoveIdentitiesMissingUserId < Gitlab::Database::Migration[2.3]
  milestone '18.4'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_user

  # it is expected this will not delete any rows. GitLab does not currently create
  # identities table entries without a user_id. This cleanup is for self-managed
  # installations in case there is corrupted data
  #
  # we use batching in case an SM instance has a large amount of these invalid
  # identity records which could cause a query timeout on delete_all
  BATCH_SIZE = 1000

  disable_ddl_transaction!

  class Identity < MigrationRecord
    include EachBatch

    self.table_name = 'identities'
  end

  def up
    Identity.each_batch(of: BATCH_SIZE) do |relation|
      relation
        .where(user_id: nil)
        .delete_all
    end
  end

  def down
    # no-op : can't un-delete records
  end
end
