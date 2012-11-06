module EventsHelper
  def link_to_author(event)
    project = event.project
    tm = project.team_member_by_id(event.author_id) if project

    if tm
      link_to event.author_name, project_team_member_path(project, tm)
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

  def event_image event
    event_image_path = if event.push?
                   "event_push.png"
                 elsif event.merged?
                   "event_mr_merged.png"
                 end

    return nil unless event_image_path

    content_tag :div, class: 'event_icon' do
      image_tag event_image_path
    end
  end

  def event_filter_link key, tooltip
    key = key.to_s

    filter = @event_filter.options key

    inactive = if @event_filter.active? key
                 nil
               else
                 'inactive'
               end

    content_tag :div, class: "filter_icon #{inactive}" do
      link_to dashboard_path(event_filter: filter), class: 'has_tooltip', 'data-original-title' => tooltip do
        image_tag "event_filter_#{key}.png"
      end
    end
  end
end
