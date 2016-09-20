class MergeRequest::Metrics < ActiveRecord::Base
  belongs_to :merge_request

  def record!
    if merge_request.merged? && self.merged_at.blank?
      self.merged_at = Time.now
    end

    self.save if self.changed?
  end
end
