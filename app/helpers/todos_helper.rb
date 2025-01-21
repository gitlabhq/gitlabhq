# frozen_string_literal: true

module TodosHelper
  def todos_pending_count
    @todos_pending_count ||= current_user.todos_pending_count
  end

  def todos_done_count
    @todos_done_count ||= current_user.todos_done_count
  end

  def todo_parent_path(todo)
    if todo.resource_parent.is_a?(Group)
      todo.resource_parent.name
    else
      # Note: Some todos (like for expired SSH keys) are neither related to a project nor a group.
      return unless todo.project.present?

      title = content_tag(:span, todo.project.name, class: 'project-name')
      namespace = content_tag(:span, "#{todo.project.namespace.human_name} / ", class: 'namespace-name')

      title.prepend(namespace) if todo.project.namespace

      title
    end
  end

  def todo_target_path(todo)
    return unless todo.target.present?

    path_options = todo_target_path_options(todo)

    if todo.for_commit?
      project_commit_path(todo.project, todo.target, path_options)
    elsif todo.for_design?
      todos_design_path(todo, path_options)
    elsif todo.for_alert?
      details_project_alert_management_path(todo.project, todo.target)
    elsif todo.for_issue_or_work_item?
      path_options[:only_path] = true
      Gitlab::UrlBuilder.build(todo.target, **path_options)
    elsif todo.for_ssh_key?
      user_settings_ssh_key_path(todo.target)
    elsif todo.member_access_requested?
      todo.access_request_url(only_path: true)
    else
      path = [todo.resource_parent, todo.target]

      path.unshift(:pipelines) if todo.build_failed?

      polymorphic_path(path, path_options)
    end
  end

  def todo_target_path_options(todo)
    { anchor: todo_target_path_anchor(todo) }
  end

  def todo_target_path_anchor(todo)
    dom_id(todo.note) if todo.note.present?
  end

  def todos_filter_params
    {
      state: params[:state].presence,
      project_id: params[:project_id],
      author_id: params[:author_id],
      type: params[:type],
      action_id: params[:action_id]
    }.compact
  end

  def todos_filter_empty?
    todos_filter_params.values.none?
  end

  def no_todos_messages
    [
      s_('Todos|Good job! Looks like you don\'t have anything left on your To-Do List'),
      s_('Todos|Isn\'t an empty To-Do List beautiful?'),
      s_('Todos|Give yourself a pat on the back!'),
      s_('Todos|Nothing left to do. High five!'),
      s_('Todos|Henceforth, you shall be known as "To-Do Destroyer"')
    ]
  end

  def todos_filter_path(options = {})
    without = options.delete(:without)

    options = todos_filter_params.merge(options)

    if without.present?
      without.each do |key|
        options.delete(key)
      end
    end

    "#{request.path}?#{options.to_param}"
  end

  def todo_actions_options
    [
      { id: '', text: s_('Todos|Any Action') },
      { id: Todo::ASSIGNED, text: s_('Todos|Assigned') },
      { id: Todo::REVIEW_REQUESTED, text: s_('Todos|Review requested') },
      { id: Todo::MENTIONED, text: s_('Todos|Mentioned') },
      { id: Todo::MARKED, text: s_('Todos|Added') },
      { id: Todo::BUILD_FAILED, text: s_('Todos|Pipelines') },
      { id: Todo::MEMBER_ACCESS_REQUESTED, text: s_('Todos|Member access requested') },
      { id: Todo::SSH_KEY_EXPIRED, text: s_('Todos|SSH key expired') },
      { id: Todo::SSH_KEY_EXPIRING_SOON, text: s_('Todos|SSH key expiring soon') }
    ]
  end

  def todo_types_options
    [
      { id: '', text: s_('Todos|Any Type') },
      { id: 'Issue', text: s_('Todos|Issue') },
      { id: 'MergeRequest', text: s_('Todos|Merge request') },
      { id: 'DesignManagement::Design', text: s_('Todos|Design') },
      { id: 'AlertManagement::Alert', text: s_('Todos|Alert') },
      { id: 'Key', text: s_('Todos|SSH key') }
    ]
  end

  def todo_actions_dropdown_label(selected_action_id, default_action)
    selected_action = todo_actions_options.find { |action| action[:id] == selected_action_id.to_i }
    selected_action ? selected_action[:text] : default_action
  end

  def todo_types_dropdown_label(selected_type, default_type)
    selected_type = todo_types_options.find { |type| type[:id] == selected_type && type[:id] != '' }
    selected_type ? selected_type[:text] : default_type
  end

  def todo_groups_requiring_saml_reauth(_todos)
    []
  end

  private

  def todos_design_path(todo, path_options)
    design = todo.target

    designs_project_issue_path(
      todo.resource_parent,
      design.issue,
      path_options.merge(
        vueroute: design.filename
      )
    )
  end

  def todo_action_subject(todo)
    todo.self_added? ? s_('Todos|yourself') : _('you')
  end

  def show_todo_state?(todo)
    case todo.target
    when MergeRequest, Issue
      %w[closed merged].include?(todo.target.state)
    when AlertManagement::Alert
      %i[resolved].include?(todo.target.state)
    else
      false
    end
  end
end

TodosHelper.prepend_mod_with('TodosHelper')
