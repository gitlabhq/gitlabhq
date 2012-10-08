class EventDecorator < ApplicationDecorator
  decorates :event

  def feed_title
    if self.issue?
      "#{self.author_name} #{self.action_name} issue ##{self.target_id}: #{self.issue_title} at #{self.project.name}"
    elsif self.merge_request?
      "#{self.author_name} #{self.action_name} MR ##{self.target_id}: #{self.merge_request_title} at #{self.project.name}"
    elsif self.push?
      "#{self.author_name} #{self.push_action_name} #{self.ref_type} #{self.ref_name} at #{self.project.name}"
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
      if self.push_with_commits?
        if self.commits_count > 1
          h.project_compare_url(self.project, :from => self.parent_commit.id, :to => self.last_commit.id)
        else
          h.project_commit_url(self.project, :id => self.last_commit.id)
        end
      else
        h.project_commits_url(self.project, self.ref_name)
      end
    end
  end

  def feed_summary
    if self.issue?
      h.render "events/event_issue", issue: self.issue
    elsif self.push?
      h.render "events/event_push", event: self
    end
  end
end
