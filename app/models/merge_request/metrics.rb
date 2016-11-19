class MergeRequest::Metrics < ActiveRecord::Base
  belongs_to :merge_request
  belongs_to :pipeline, class_name: 'Ci::Pipeline', foreign_key: :pipeline_id

  def record!
    if merge_request.merged? && self.merged_at.blank?
      self.merged_at = Time.now
    end

    self.save
  end
end
