class MergeRequest::Metrics < ActiveRecord::Base
  belongs_to :merge_request

  def record!
    if !merge_request.work_in_progress? && self.wip_flag_first_removed_at.blank?
      self.wip_flag_first_removed_at = Time.now
    end

    if merge_request.author_id != merge_request.assignee_id && self.first_assigned_to_user_other_than_author.blank?
      self.first_assigned_to_user_other_than_author = Time.now
    end

    self.save if self.changed?
  end
end
