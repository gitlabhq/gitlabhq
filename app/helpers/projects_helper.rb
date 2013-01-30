module ProjectsHelper
  def grouper_project_members(project)
    @project.users_projects.sort_by(&:project_access).reverse.group_by(&:project_access)
  end

  def grouper_project_teams(project)
    @project.user_team_project_relationships.sort_by(&:greatest_access).reverse.group_by(&:greatest_access)
  end

  def remove_from_project_team_message(project, user)
    "You are going to remove #{user.name} from #{project.name} project team. Are you sure?"
  end

  def link_to_project project
    link_to project do
      title = content_tag(:strong, project.name)

      if project.namespace
        namespace = content_tag(:span, "#{project.namespace.human_name} / ", class: 'tiny')
        title = namespace + title
      end

      title
    end
  end

  def link_to_member(project, author, opts = {})
    default_opts = { avatar: true }
    opts = default_opts.merge(opts)

    return "(deleted)" unless author

    author_html =  ""

    # Build avatar image tag
    author_html << image_tag(gravatar_icon(author.try(:email)), width: 16, class: "lil_av") if opts[:avatar]

    # Build name span tag
    author_html << content_tag(:span, sanitize(author.name), class: 'author')

    author_html = author_html.html_safe

    tm = project.team_member_by_id(author)

    if tm
      link_to author_html, project_team_member_path(project, tm.user_username), class: "author_link"
    else
      author_html
    end.html_safe
  end

  def tm_path team_member
    project_team_member_path(@project, team_member)
  end

  def project_title project
    if project.group
      content_tag :span do
        link_to(project.group.name, group_path(project.group)) + " / " + project.name
      end
    else
      project.name
    end
  end
end
