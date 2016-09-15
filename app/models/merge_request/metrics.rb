class MergeRequest::Metrics < ActiveRecord::Base
  belongs_to :merge_request

  def record!
    if !merge_request.work_in_progress? && self.wip_flag_first_removed_at.blank?
      self.wip_flag_first_removed_at = Time.now
    end

    if merge_request.author_id != merge_request.assignee_id && self.first_assigned_to_user_other_than_author.blank?
      self.first_assigned_to_user_other_than_author = Time.now
    end

    if merge_request.merged? && self.merged_at.blank?
      self.merged_at = Time.now
    end

    if merge_request.closed? && self.first_closed_at.blank?
      self.first_closed_at = Time.now
    end

    self.save if self.changed?
  end

  def record_production_deploy!(deploy_time)
    self.update(first_deployed_to_production_at: deploy_time) if self.first_deployed_to_production_at.blank?
  end

  def record_latest_build_start_time!(start_time)
    self.update(latest_build_started_at: start_time, latest_build_finished_at: nil)
  end

  def record_latest_build_finish_time!(finish_time)
    self.update(latest_build_finished_at: finish_time)
  end
end
