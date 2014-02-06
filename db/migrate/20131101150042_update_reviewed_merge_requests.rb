class UpdateReviewedMergeRequests < ActiveRecord::Migration
  def up
    # Update all merge requests in the review states (:accepted, :rejected, :fixed)
    # This is normally done in Project.update_merge_requests(oldrev, newrev, ref, user) via a push hook,
    # but only opened MRs were updated before, so we need to update the reviewed ones now
    MergeRequest.where(state: [:accepted, :rejected, :fixed]).each { |merge_request| merge_request.reload_code; merge_request.mark_as_unchecked }
  end
end
