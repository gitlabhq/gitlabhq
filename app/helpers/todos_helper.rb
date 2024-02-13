# frozen_string_literal: true

module TodosHelper
  def todos_pending_count
    @todos_pending_count ||= current_user.todos_pending_count
  end

  def todos_done_count
    @todos_done_count ||= current_user.todos_done_count
  end

  def todo_action_name(todo)
    case todo.action
    when Todo::ASSIGNED then todo.self_added? ? _('assigned') : _('assigned you')
    when Todo::REVIEW_REQUESTED then s_('Todos|requested a review')
    when Todo::MENTIONED, Todo::DIRECTLY_ADDRESSED then format(
      s_("Todos|mentioned %{who}"), who: todo_action_subject(todo)
    )
    when Todo::BUILD_FAILED then s_('Todos|The pipeline failed')
    when Todo::MARKED then s_('Todos|added a to-do item')
    when Todo::APPROVAL_REQUIRED then format(
      s_("Todos|set %{who} as an approver"), who: todo_action_subject(todo)
    )
    when Todo::UNMERGEABLE then s_('Todos|Could not merge')
    when Todo::MERGE_TRAIN_REMOVED then s_("Todos|Removed from Merge Train")
    when Todo::MEMBER_ACCESS_REQUESTED then format(
      s_("Todos|has requested access to %{what} %{which}"), what: _(todo.member_access_type), which: _(todo.target.name)
    )
    when Todo::REVIEW_SUBMITTED then s_('Todos|reviewed your merge request')
    when Todo::OKR_CHECKIN_REQUESTED then format(
      s_("Todos|requested an OKR update for %{what}"), what: todo.target.title
    )
    end
  end

  def todo_self_addressing(todo)
    case todo.action
    when Todo::ASSIGNED then _('to yourself')
    when Todo::REVIEW_REQUESTED then _('from yourself')
    end
  end

  def todo_target_name(todo)
    return todo.target_reference unless todo.for_commit?

    content_tag(:span, todo.target_reference, class: 'commit-sha')
  end

  def todo_target_title(todo)
    # Design To Dos' filenames are displayed in `#todo_target_name` (see `Design#to_reference`),
    # so to avoid displaying duplicate filenames in the To Do list for designs,
    # we return an empty string here.
    return "" if todo.target.blank? || todo.for_design? || todo.member_access_requested?

    todo.target.title.to_s
  end

  def todo_parent_path(todo)
    if todo.resource_parent.is_a?(Group)
      todo.resource_parent.name
    else
      title = content_tag(:span, todo.project.name, class: 'project-name')
      namespace = content_tag(:span, "#{todo.project.namespace.human_name} / ", class: 'namespace-name')

      title.prepend(namespace) if todo.project.namespace

      title
    end
  end

  def todo_target_aria_label(todo)
    target_type = if todo.for_design?
                    _('Design')
                  elsif todo.for_alert?
                    _('Alert')
                  elsif todo.member_access_requested?
                    _('Group')
                  elsif todo.for_issue_or_work_item?
                    IntegrationsHelper.integration_issue_type(todo.target.issue_type)
                  else
                    IntegrationsHelper.integration_todo_target_type(todo.target_type)
                  end

    "#{target_type} #{todo_target_name(todo)}"
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

  def todo_target_state_pill(todo)
    return unless show_todo_state?(todo)

    state = todo.target.state.to_s
    raw_state_to_i18n = {
      "closed" => _('Closed'),
      "merged" => _('Merged'),
      "resolved" => _('Resolved')
    }

    case todo.target
    when MergeRequest
      case state
      when 'closed'
        variant = 'danger'
      when 'merged'
        variant = 'info'
      end
    when Issue
      variant = 'info' if state == 'closed'
    when AlertManagement::Alert
      variant = 'info' if state == 'resolved'
    else
      variant = 'info'
    end

    content_tag(:span, class: 'todo-target-state') do
      gl_badge_tag(raw_state_to_i18n[state] || state.capitalize, { variant: variant, size: 'sm' })
    end
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

  def todos_has_filtered_results?
    params[:group_id] || params[:project_id] || params[:author_id] || params[:type] || params[:action_id]
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
      { id: Todo::MEMBER_ACCESS_REQUESTED, text: s_('Todos|Member access requested') }
    ]
  end

  def todo_types_options
    [
      { id: '', text: s_('Todos|Any Type') },
      { id: 'Issue', text: s_('Todos|Issue') },
      { id: 'MergeRequest', text: s_('Todos|Merge request') },
      { id: 'DesignManagement::Design', text: s_('Todos|Design') },
      { id: 'AlertManagement::Alert', text: s_('Todos|Alert') }
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

  def todo_due_date(todo)
    return unless todo.target.try(:due_date)

    is_due_today = todo.target.due_date.today?
    is_overdue = todo.target.overdue?
    css_class =
      if is_due_today
        'text-warning'
      elsif is_overdue
        'text-danger'
      else
        ''
      end

    due_date =
      if is_due_today
        _("today")
      else
        l(todo.target.due_date, format: Date::DATE_FORMATS[:medium])
      end

    content = content_tag(:span, class: css_class) do
      format(s_("Todos|Due %{due_date}"), due_date: due_date)
    end

    "#{content} &middot;".html_safe
  end

  def todo_author_display?(todo)
    !todo.build_failed? && !todo.unmergeable?
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
