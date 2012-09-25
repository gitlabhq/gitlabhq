class EventDecorator < ApplicationDecorator
  decorates :event

  def feed_title
    if self.issue?
      "#{self.author_name} #{self.action_name} issue ##{self.target_id}:" + self.issue_title
    elsif self.merge_request?
      "#{self.author_name} #{self.action_name} MR ##{self.target_id}:" + self.merge_request_title
    elsif self.push?
      "#{self.author_name} #{self.push_action_name} #{self.ref_type} " + self.ref_name
    elsif self.membership_changed?
      "#{self.author_name} #{self.action_name} #{self.project.name}"
    else
      ""
    end
  end

  def feed_url
    if self.issue?
      h.project_issue_url(self.project, self.issue)
    elsif self.merge_request?
      h.project_merge_request_url(self.project, self.merge_request)
    elsif self.push?
      h.project_commits_url(self.project, self.ref_name)
    end
  end
end
