class ConvertClosedToStateInMergeRequest < ActiveRecord::Migration
  def up
    MergeRequest.transaction do
      MergeRequest.where("closed = 1 AND merged = 1").update_all("state = 'merged'")
      MergeRequest.where("closed = 1 AND merged = 0").update_all("state = 'closed'")
      MergeRequest.where("closed = 0").update_all("state = 'opened'")
    end
  end

  def down
    MergeRequest.transaction do
      MergeRequest.where(state: :closed).update_all("closed = 1")
      MergeRequest.where(state: :merged).update_all("closed = 1, merged = 1")
    end
  end
end
