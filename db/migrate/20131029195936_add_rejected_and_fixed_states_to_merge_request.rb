class AddRejectedAndFixedStatesToMergeRequest < ActiveRecord::Migration
  # We don't need the forward ("up") data migration
  def down
    # Return all rejected and fixed MR's back to the 'opened' state
    MergeRequest.where(state: [:rejected, :fixed]).update_all(state: :opened)
  end
end
