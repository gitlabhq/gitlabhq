class ChangeStateToAllowEmptyMergeRequestDiffs < ActiveRecord::Migration[4.2]
  def up
    change_column :merge_request_diffs, :state, :string, null: true,
                  default: nil
  end

  def down
    change_column :merge_request_diffs, :state, :string, null: false,
                  default: 'collected'
  end
end
