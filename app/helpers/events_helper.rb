module EventsHelper
  def link_to_author(event)
    project = event.project
    tm = project.team_member_by_id(event.author_id)

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
end
