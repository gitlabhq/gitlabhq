class ConvertClosedToStateInMergeRequest < ActiveRecord::Migration
  def up
    MergeRequest.transaction do
      MergeRequest.where(closed: true, merged: true).update_all(state: :merged)
      MergeRequest.where(closed: true, merged: false).update_all(state: :closed)
      MergeRequest.where(closed: false).update_all(state: :opened)
    end
  end

  def down
    MergeRequest.transaction do
      MergeRequest.where(state: :closed).update_all(closed: true)
      MergeRequest.where(state: :merged).update_all(closed: true, merged: true)
    end
  end
end
