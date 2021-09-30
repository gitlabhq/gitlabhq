# frozen_string_literal: true

class CleanupOrphanProjectAccessTokens < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  TMP_INDEX_NAME = 'idx_users_on_user_type_project_bots_batched'

  def up
    users_table = define_batchable_model('users')

    add_concurrent_index(:users, :id, name: TMP_INDEX_NAME, where: 'user_type = 6')

    accumulated_orphans = []
    users_table.where(user_type: 6).each_batch(of: 500) do |relation|
      orphan_ids = relation.where("not exists(select 1 from members where members.user_id = users.id)").pluck(:id)

      orphan_ids.each_slice(10) do |ids|
        users_table.where(id: ids).update_all(state: 'deactivated')
      end

      accumulated_orphans += orphan_ids
    end

    schedule_deletion(accumulated_orphans)
  ensure
    remove_concurrent_index_by_name(:users, TMP_INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(:users, TMP_INDEX_NAME) if index_exists_by_name?(:users, TMP_INDEX_NAME)
  end

  private

  def schedule_deletion(orphan_ids)
    return unless deletion_worker

    orphan_ids.each_slice(100) do |ids|
      job_arguments = ids.map do |orphan_id|
        [orphan_id, orphan_id, { skip_authorization: true }]
      end

      deletion_worker.bulk_perform_async(job_arguments)
    end
  rescue StandardError
    # Ignore any errors or interface changes since this part of migration is optional
  end

  def deletion_worker
    @deletion_worker = "DeleteUserWorker".safe_constantize unless defined?(@deletion_worker)

    @deletion_worker
  end
end
