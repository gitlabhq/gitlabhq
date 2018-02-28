module EventsHelper
  ICON_NAMES_BY_EVENT_TYPE = {
    'pushed to' => 'commit',
    'pushed new' => 'commit',
    'created' => 'status_open',
    'opened' => 'status_open',
    'closed' => 'status_closed',
    'accepted' => 'fork',
    'commented on' => 'comment',
    'deleted' => 'remove',
    'imported' => 'import',
    'joined' => 'users'
  }.freeze

  def link_to_author(event, self_added: false)
    author = event.author

    if author
      name = self_added ? 'You' : author.name
      link_to name, user_path(author.username), title: name
    else
      event.author_name
    end
  end

  def event_action_name(event)
    target =  if event.target_type
                if event.note?
                  event.note_target_type
                else
                  event.target_type.titleize.downcase
                end
              else
                'project'
              end

    [event.action_name, target].join(" ")
  end

  def event_filter_link(key, text, tooltip)
    key = key.to_s
    active = 'active' if @event_filter.active?(key)
    link_opts = {
      class: "event-filter-link has-tooltip",
      id:    "#{key}_event_filter",
      title: tooltip
    }

    content_tag :li, class: active do
      link_to request.path, link_opts do
        content_tag(:span, ' ' + text)
      end
    end
  end

  def event_filter_visible(feature_key)
    return true unless @project

    @project.feature_available?(feature_key, current_user)
  end

  def comments_visible?
    event_filter_visible(:repository) ||
      event_filter_visible(:merge_requests) ||
      event_filter_visible(:issues)
  end

  def event_preposition(event)
    if event.push? || event.commented? || event.target
      "at"
    elsif event.milestone?
      "in"
    end
  end

  def event_feed_title(event)
    words = []
    words << event.author_name
    words << event_action_name(event)

    if event.push?
      words << event.ref_type
      words << event.ref_name
      words << "at"
    elsif event.commented?
      words << event.note_target_reference
      words << "at"
    elsif event.milestone?
      words << "##{event.target_iid}" if event.target_iid
      words << "in"
    elsif event.target
      words << "##{event.target_iid}:"
      words << event.target.title if event.target.respond_to?(:title)
      words << "at"
    end

    words << event.project_name

    words.join(" ")
  end

  def event_feed_url(event)
    if event.issue?
      project_issue_url(event.project,
                                  event.issue)
    elsif event.merge_request?
      project_merge_request_url(event.project, event.merge_request)
    elsif event.commit_note?
      project_commit_url(event.project,
                                   event.note_target)
    elsif event.note?
      if event.note_target
        event_note_target_path(event)
      end
    elsif event.push?
      push_event_feed_url(event)
    end
  end

  def push_event_feed_url(event)
    if event.push_with_commits? && event.md_ref?
      if event.commits_count > 1
        project_compare_url(event.project,
                                      from: event.commit_from, to:
                                      event.commit_to)
      else
        project_commit_url(event.project,
                                     id: event.commit_to)
      end
    else
      project_commits_url(event.project,
                                    event.ref_name)
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
    if event.commit_note?
      project_commit_path(event.project, event.note_target, anchor: dom_id(event.target))
    elsif event.project_snippet_note?
      project_snippet_path(event.project, event.note_target, anchor: dom_id(event.target))
    else
      polymorphic_path([event.project.namespace.becomes(Namespace),
                        event.project, event.note_target],
                        anchor: dom_id(event.target))
    end
  end

  def event_note_title_html(event)
    if event.note_target
      text = raw("#{event.note_target_type} ") +
        if event.commit_note?
          content_tag(:span, event.note_target_reference, class: 'commit-sha')
        else
          event.note_target_reference
        end

      link_to(text, event_note_target_path(event), title: event.target_title, class: 'has-tooltip')
    else
      content_tag(:strong, '(deleted)')
    end
  end

  def event_commit_title(message)
    message ||= ''
    (message.split("\n").first || "").truncate(70)
  rescue
    "--broken encoding"
  end

  def event_row_class(event)
    if event.body?
      "event-block"
    else
      "event-inline"
    end
  end

  def icon_for_event(note)
    icon_name = ICON_NAMES_BY_EVENT_TYPE[note]
    sprite_icon(icon_name) if icon_name
  end

  def icon_for_profile_event(event)
    if current_path?('users#show')
      content_tag :div, class: "system-note-image #{event.action_name.parameterize}-icon" do
        icon_for_event(event.action_name)
      end
    else
      content_tag :div, class: 'system-note-image user-avatar' do
        author_avatar(event, size: 32)
      end
    end
  end
end
