# frozen_string_literal: true

class AddUniqueConstraintToApprovalsUserIdAndMergeRequestId < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_duplicates
    add_concurrent_index :approvals, [:user_id, :merge_request_id], unique: true
  end

  def down
    remove_concurrent_index :approvals, [:user_id, :merge_request_id]
  end

  private

  def remove_duplicates
    add_concurrent_index :approvals, [:user_id, :merge_request_id, :id]

    if Gitlab::Database.mysql?
      execute <<-SQL
        DELETE FROM a
        USING approvals AS a
        INNER JOIN (
          SELECT user_id, merge_request_id, MIN(id) as min_id
          FROM approvals
          GROUP BY user_id, merge_request_id
          HAVING COUNT(id) > 1
        ) as approvals_with_duplicates
        ON approvals_with_duplicates.user_id = a.user_id
        AND approvals_with_duplicates.merge_request_id = a.merge_request_id
        WHERE approvals_with_duplicates.min_id <> a.id;
      SQL
    else
      execute <<-SQL
        DELETE FROM approvals
        USING (
          SELECT user_id, merge_request_id, MIN(id) as min_id
          FROM approvals
          GROUP BY user_id, merge_request_id
          HAVING COUNT(id) > 1
        ) as approvals_with_duplicates
        WHERE approvals_with_duplicates.user_id = approvals.user_id
        AND approvals_with_duplicates.merge_request_id = approvals.merge_request_id
        AND approvals_with_duplicates.min_id <> approvals.id;
      SQL
    end

    remove_concurrent_index :approvals, [:user_id, :merge_request_id, :id]
  end
end
