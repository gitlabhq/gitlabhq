class ChangeStateToAllowEmptyMergeRequestDiffs < ActiveRecord::Migration
  def up
    change_column :merge_request_diffs, :state, :string, null: true,
                  default: nil
  end

  def down
    change_column :merge_request_diffs, :state, :string, null: false,
                  default: 'collected'
  end
end
