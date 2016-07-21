# online without errors
# This migration makes an actual field now there are more usecases for this field
# Migrating the data between the `merge_params` hash and this field will happen as
# part of this migration, but cleaning up the merge_params field will not. So some
# keys will be there but never used.
class AddRemoveSourceBranchToMergeRequests < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_column_with_default(:merge_requests, :remove_source_branch, :boolean, default: true)

    set_to_true = if Gitlab::Database.postgresql?
                    execute "SELECT id FROM merge_requests WHERE merge_params ~* 'remove_source_branch:.+1';"
                  else
                    execute "SELECT id FROM merge_requests WHERE merge_params REGEXP 'remove_source_branch:.+1;'"
                  end

    set_to_true.each_slice(1000) do |ids|
      MergeRequest.where(id: ids).update_all(remove_source_branch: true)
    end
  end

  def down
    # noop - We don't want to serialize and deserialize, also, the keys are still there
  end
end
