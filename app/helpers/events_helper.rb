module EventsHelper
  def link_to_author(event)
    author = event.author

    if author
      link_to author.name, user_path(author.username)
    else
      event.author_name
    end
  end

  def event_action_name(event)
    target = if event.target_type
               event.target_type.titleize.downcase
             else
               'project'
             end

    [event.action_name, target].join(" ")
  end

  def event_filter_link key, tooltip
    key = key.to_s
    inactive = if @event_filter.active? key
                 nil
               else
                 'inactive'
               end

    content_tag :div, class: "filter_icon #{inactive}" do
      link_to dashboard_path, class: 'has_tooltip event_filter_link', id: "#{key}_event_filter", 'data-original-title' => tooltip do
        content_tag :i, nil, class: icon_for_event[key]
      end
    end
  end

  def icon_for_event
    {
      EventFilter.push     => "icon-upload-alt",
      EventFilter.merged   => "icon-check",
      EventFilter.comments => "icon-comments",
      EventFilter.team     => "icon-user",
    }
  end

  def event_feed_title(event)
    if event.issue?
      "#{event.author_name} #{event.action_name} issue ##{event.target_id}: #{event.issue_title} at #{event.project.name}"
    elsif event.merge_request?
      "#{event.author_name} #{event.action_name} MR ##{event.target_id}: #{event.merge_request_title} at #{event.project.name}"
    elsif event.push?
      "#{event.author_name} #{event.push_action_name} #{event.ref_type} #{event.ref_name} at #{event.project.name}"
    elsif event.membership_changed?
      "#{event.author_name} #{event.action_name} #{event.project.name}"
    else
      ""
    end
  end

  def event_feed_url(event)
    if event.issue?
      project_issue_url(event.project, event.issue)
    elsif event.merge_request?
      project_merge_request_url(event.project, event.merge_request)

    elsif event.push?
      if event.push_with_commits?
        if event.commits_count > 1
          project_compare_url(event.project, from: event.commit_from, to: event.commit_to)
        else
          project_commit_url(event.project, id: event.commit_to)
        end
      else
        project_commits_url(event.project, event.ref_name)
      end
    end
  end

  def event_feed_summary(event)
    if event.issue?
      render "events/event_issue", issue: event.issue
    elsif event.push?
      render "events/event_push", event: event
    end
  end

  def event_note_target_path(event)
    if event.note? && event.note_commit?
      project_commit_path(event.project, event.note_target)
    else
      url_for([event.project, event.note_target])
    end
  end
end
