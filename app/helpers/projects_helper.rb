module ProjectsHelper
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
    author_html << image_tag(gravatar_icon(author.try(:email)), width: 16, class: "avatar avatar-inline s16") if opts[:avatar]

    # Build name span tag
    author_html << content_tag(:span, sanitize(author.name), class: 'author')

    author_html = author_html.html_safe

    link_to(author_html, user_path(author), class: "author_link").html_safe
  end

  def project_title project
    if project.group
      content_tag :span do
        link_to(simple_sanitize(project.group.name), group_path(project.group)) + " / " + project.name
      end
    else
      project.name
    end
  end
end
