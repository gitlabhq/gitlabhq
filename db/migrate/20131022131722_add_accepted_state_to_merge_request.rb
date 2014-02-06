class AddAcceptedStateToMergeRequest < ActiveRecord::Migration
  # We don't need the forward ("up") data migration
  def down
    # Return all 'accepted' MR's back to the 'opened' state
    MergeRequest.where(state: :accepted).update_all(state: :opened)
  end
end
