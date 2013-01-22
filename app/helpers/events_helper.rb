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
end
