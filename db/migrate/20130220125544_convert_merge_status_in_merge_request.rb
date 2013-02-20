class ConvertMergeStatusInMergeRequest < ActiveRecord::Migration
  def up
    MergeRequest.transaction do
      MergeRequest.where(merge_status: 1).update_all("new_merge_status = 'unchecked'")
      MergeRequest.where(merge_status: 2).update_all("new_merge_status = 'can_be_merged'")
      MergeRequest.where(merge_status: 3).update_all("new_merge_status = 'cannot_be_merged'")
    end
  end

  def down
    MergeRequest.transaction do
      MergeRequest.where(new_merge_status: :unchecked).update_all("merge_status = 1")
      MergeRequest.where(new_merge_status: :can_be_merged).update_all("merge_status = 2")
      MergeRequest.where(new_merge_status: :cannot_be_merged).update_all("merge_status = 3")
    end
  end
end
