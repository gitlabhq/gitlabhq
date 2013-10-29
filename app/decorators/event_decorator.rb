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
    elsif self.note?
      "#{self.author_name} #{self.action_name} '#{self.note_note}' on #{self.project.name}"
    else
      ""
    end
  end

  def feed_url
    if self.issue?
      h.project_issue_url(self.project, self.issue)
    elsif self.note?
	if self.note_target_type == "issue"
	    h.project_issue_url(self.project, self.note_target_id, anchor: "note_#{self.note_id}")
	elsif self.note_target_type == "maprequest"
	    h.project_merge_request_url(self.project, self.note_target_id, anchor: "note_#{self.note_id}")
	else
		h.wall_project_url(self.project, anchor: "note_#{self.note_id}")
	end
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
