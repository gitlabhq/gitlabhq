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
      link_to request.path, class: 'has_tooltip event_filter_link', id: "#{key}_event_filter", 'data-original-title' => tooltip do
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
      "#{event.author_name} #{event.action_name} issue ##{event.target_iid}: #{event.issue_title} at #{event.project_name}"
    elsif event.merge_request?
      "#{event.author_name} #{event.action_name} MR ##{event.target_iid}: #{event.merge_request_title} at #{event.project_name}"
    elsif event.push?
      "#{event.author_name} #{event.push_action_name} #{event.ref_type} #{event.ref_name} at #{event.project_name}"
    elsif event.membership_changed?
      "#{event.author_name} #{event.action_name} #{event.project_name}"
    elsif event.note?
      "#{event.author_name} commented on #{event.note_target_type} ##{truncate event.note_target_iid} at #{event.project_name}"
    else
      ""
    end
  end

  def event_feed_url(event)
    if event.issue?
      project_issue_url(event.project, event.issue)
    elsif event.merge_request?
      project_merge_request_url(event.project, event.merge_request)
    elsif event.note?
      if event.note_target
        if event.note_commit?
          project_commit_path(event.project, event.note_commit_id, anchor: dom_id(event.target))
        elsif event.note_project_snippet?
          project_snippet_path(event.project, event.note_target)
        else
          event_note_target_path(event)
        end
      end
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
    elsif event.merge_request?
      render "events/event_merge_request", merge_request: event.merge_request
    elsif event.note?
      render "events/event_note", note: event.note
    end
  end

  def event_note_target_path(event)
    if event.note? && event.note_commit?
      project_commit_path(event.project, event.note_target)
    else
      polymorphic_path([event.project, event.note_target], anchor: dom_id(event.target))
    end
  end

  def event_note_title_html(event)
    if event.note_target
      if event.note_commit?
        link_to project_commit_path(event.project, event.note_commit_id, anchor: dom_id(event.target)), class: "commit_short_id" do
          "#{event.note_target_type} #{event.note_short_commit_id}"
        end
      elsif event.note_project_snippet?
        link_to(project_snippet_path(event.project, event.note_target)) do
          "#{event.note_target_type} ##{truncate event.note_target_id}"
        end
      else
        link_to event_note_target_path(event) do
          "#{event.note_target_type} ##{truncate event.note_target_iid}"
        end
      end
    else
      content_tag :strong do
        "(deleted)"
      end
    end
  end

  def event_note(text)
    text = first_line(text)
    text = truncate(text, length: 150)
    sanitize(markdown(text), tags: %w(a img b pre p))
  end

  def event_commit_title(message)
    escape_once(truncate(message.split("\n").first, length: 70))
  rescue
    "--broken encoding"
  end
end
