# frozen_string_literal: true

class RemoveOrphanGroupTokenUsers < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  disable_ddl_transaction!

  class MigrationUser < MigrationRecord
    include EachBatch

    self.table_name = 'users'

    scope :project_bots, -> { where(user_type: 6) }
    scope :without_memberships, -> { where("NOT EXISTS (SELECT 1 FROM members where members.user_id = users.id)") }
  end

  class MigrationPersonalAccessToken < MigrationRecord
    self.table_name = 'personal_access_tokens'
  end

  def up
    delete_worker = 'DeleteUserWorker'.safe_constantize

    MigrationUser.project_bots.each_batch(of: 1000) do |batch|
      bot_ids = batch.without_memberships.pluck(:id)

      MigrationPersonalAccessToken.where(user_id: bot_ids).delete_all

      next unless delete_worker && delete_worker.respond_to?(:perform_async)

      bot_ids.each do |bot_id|
        delete_worker.perform_async(bot_id, bot_id, skip_authorization: true)
      end
    end
  end

  def down
    # no-op
  end
end
