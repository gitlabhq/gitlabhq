module IssuablesHelper
  include GitlabRoutingHelper

  def sidebar_gutter_toggle_icon
    sidebar_gutter_collapsed? ? icon('angle-double-left', { 'aria-hidden': 'true' }) : icon('angle-double-right', { 'aria-hidden': 'true' })
  end

  def sidebar_gutter_collapsed_class
    "right-sidebar-#{sidebar_gutter_collapsed? ? 'collapsed' : 'expanded'}"
  end

  def multi_label_name(current_labels, default_label)
    if current_labels && current_labels.any?
      title = current_labels.first.try(:title)
      if current_labels.size > 1
        "#{title} +#{current_labels.size - 1} more"
      else
        title
      end
    else
      default_label
    end
  end

  def issuable_json_path(issuable)
    project = issuable.project

    if issuable.is_a?(MergeRequest)
      project_merge_request_path(project, issuable.iid, :json)
    else
      project_issue_path(project, issuable.iid, :json)
    end
  end

  def serialize_issuable(issuable)
    case issuable
    when Issue
      IssueSerializer.new.represent(issuable).to_json
    when MergeRequest
      MergeRequestSerializer
        .new(current_user: current_user, project: issuable.project)
        .represent(issuable)
        .to_json
    end
  end

  def template_dropdown_tag(issuable, &block)
    title = selected_template(issuable) || "Choose a template"
    options = {
      toggle_class: 'js-issuable-selector',
      title: title,
      filter: true,
      placeholder: 'Filter',
      footer_content: true,
      data: {
        data: issuable_templates(issuable),
        field_name: 'issuable_template',
        selected: selected_template(issuable),
        project_path: ref_project.path,
        namespace_path: ref_project.namespace.full_path
      }
    }

    dropdown_tag(title, options: options) do
      capture(&block)
    end
  end

  def users_dropdown_label(selected_users)
    case selected_users.length
    when 0
      "Unassigned"
    when 1
      selected_users[0].name
    else
      "#{selected_users[0].name} + #{selected_users.length - 1} more"
    end
  end

  def user_dropdown_label(user_id, default_label)
    return default_label if user_id.nil?
    return "Unassigned" if user_id == "0"

    user = User.find_by(id: user_id)

    if user
      user.name
    else
      default_label
    end
  end

  def project_dropdown_label(project_id, default_label)
    return default_label if project_id.nil?
    return "Any project" if project_id == "0"

    project = Project.find_by(id: project_id)

    if project
      project.name_with_namespace
    else
      default_label
    end
  end

  def milestone_dropdown_label(milestone_title, default_label = "Milestone")
    title =
      case milestone_title
      when Milestone::Upcoming.name then Milestone::Upcoming.title
      when Milestone::Started.name then Milestone::Started.title
      else milestone_title.presence
      end

    h(title || default_label)
  end

  def to_url_reference(issuable)
    case issuable
    when Issue
      link_to issuable.to_reference, issue_url(issuable)
    when MergeRequest
      link_to issuable.to_reference, merge_request_url(issuable)
    else
      issuable.to_reference
    end
  end

  def issuable_meta(issuable, project, text)
    output = content_tag(:strong, class: "identifier") do
      concat("#{text} ")
      concat(to_url_reference(issuable))
    end

    output << " opened #{time_ago_with_tooltip(issuable.created_at)} by ".html_safe
    output << content_tag(:strong) do
      author_output = link_to_member(project, issuable.author, size: 24, mobile_classes: "hidden-xs", tooltip: true)
      author_output << link_to_member(project, issuable.author, size: 24, by_username: true, avatar: false, mobile_classes: "hidden-sm hidden-md hidden-lg")
    end

    output << "&ensp;".html_safe
    output << content_tag(:span, (issuable.task_status if issuable.tasks?), id: "task_status", class: "hidden-xs hidden-sm")
    output << content_tag(:span, (issuable.task_status_short if issuable.tasks?), id: "task_status_short", class: "hidden-md hidden-lg")

    output
  end

  def issuable_todo(issuable)
    if current_user
      current_user.todos.find_by(target: issuable, state: :pending)
    end
  end

  def issuable_labels_tooltip(labels, limit: 5)
    first, last = labels.partition.with_index{ |_, i| i < limit  }

    label_names = first.collect(&:name)
    label_names << "and #{last.size} more" unless last.empty?

    label_names.join(', ')
  end

  def issuables_state_counter_text(issuable_type, state)
    titles = {
      opened: "Open"
    }

    state_title = titles[state] || state.to_s.humanize
    count = issuables_count_for_state(issuable_type, state)

    html = content_tag(:span, state_title)
    html << " " << content_tag(:span, number_with_delimiter(count), class: 'badge')

    html.html_safe
  end

  def cached_assigned_issuables_count(assignee, issuable_type, state)
    cache_key = hexdigest(['assigned_issuables_count', assignee.id, issuable_type, state].join('-'))
    Rails.cache.fetch(cache_key, expires_in: 2.minutes) do
      assigned_issuables_count(assignee, issuable_type, state)
    end
  end

  def assigned_issuables_count(issuable_type)
    current_user.public_send("assigned_open_#{issuable_type}_count")
  end

  def issuable_filter_params
    [
      :search,
      :author_id,
      :assignee_id,
      :milestone_title,
      :weight,
      :label_name
    ]
  end

  def issuable_reference(issuable)
    @show_full_reference ? issuable.to_reference(full: true) : issuable.to_reference(@group || @project)
  end

  def issuable_filter_present?
    issuable_filter_params.any? { |k| params.key?(k) }
  end

  def issuable_initial_data(issuable)
    data = {
      endpoint: project_issue_path(@project, issuable),
      canUpdate: can?(current_user, :update_issue, issuable),
      canDestroy: can?(current_user, :destroy_issue, issuable),
      canMove: current_user ? issuable.can_move?(current_user) : false,
      issuableRef: issuable.to_reference,
      isConfidential: issuable.confidential,
      markdownPreviewUrl: preview_markdown_path(@project),
      markdownDocs: help_page_path('user/markdown'),
      projectsAutocompleteUrl: autocomplete_projects_path(project_id: @project.id),
      issuableTemplates: issuable_templates(issuable),
      projectPath: ref_project.path,
      projectNamespace: ref_project.namespace.full_path,
      initialTitleHtml: markdown_field(issuable, :title),
      initialTitleText: issuable.title,
      initialDescriptionHtml: markdown_field(issuable, :description),
      initialDescriptionText: issuable.description,
      initialTaskStatus: issuable.task_status
    }

    data.merge!(updated_at_by(issuable))

    data.to_json
  end

  def updated_at_by(issuable)
    return {} unless issuable.is_edited?

    {
      updatedAt: issuable.updated_at.to_time.iso8601,
      updatedBy: {
        name: issuable.last_edited_by.name,
        path: user_path(issuable.last_edited_by)
      }
    }
  end

  def issuables_count_for_state(issuable_type, state, finder: nil)
    finder ||= public_send("#{issuable_type}_finder")
    cache_key = finder.state_counter_cache_key

    @counts ||= {}
    @counts[cache_key] ||= Rails.cache.fetch(cache_key, expires_in: 2.minutes) do
      finder.count_by_state
    end

    @counts[cache_key][state]
  end

  def close_issuable_url(issuable)
    issuable_url(issuable, close_reopen_params(issuable, :close))
  end

  def reopen_issuable_url(issuable)
    issuable_url(issuable, close_reopen_params(issuable, :reopen))
  end

  def close_reopen_issuable_url(issuable, should_inverse = false)
    issuable.closed? ^ should_inverse ? reopen_issuable_url(issuable) : close_issuable_url(issuable)
  end

  def issuable_url(issuable, *options)
    case issuable
    when Issue
      issue_url(issuable, *options)
    when MergeRequest
      merge_request_url(issuable, *options)
    end
  end

  def issuable_button_visibility(issuable, closed)
    case issuable
    when Issue
      issue_button_visibility(issuable, closed)
    when MergeRequest
      merge_request_button_visibility(issuable, closed)
    end
  end

  def issuable_close_reopen_button_method(issuable)
    case issuable
    when Issue
      ''
    when MergeRequest
      'put'
    end
  end

  def issuable_author_is_current_user(issuable)
    issuable.author == current_user
  end

  def issuable_display_type(issuable)
    issuable.model_name.human.downcase
  end

  private

  def sidebar_gutter_collapsed?
    cookies[:collapsed_gutter] == 'true'
  end

  def base_issuable_scope(issuable)
    issuable.project.send(issuable.class.table_name).send(issuable_state_scope(issuable))
  end

  def issuable_state_scope(issuable)
    if issuable.respond_to?(:merged?) && issuable.merged?
      :merged
    else
      issuable.open? ? :opened : :closed
    end
  end

  def issuable_templates(issuable)
    @issuable_templates ||=
      case issuable
      when Issue
        issue_template_names
      when MergeRequest
        merge_request_template_names
      end
  end

  def merge_request_template_names
    @merge_request_templates ||= Gitlab::Template::MergeRequestTemplate.dropdown_names(ref_project)
  end

  def issue_template_names
    @issue_templates ||= Gitlab::Template::IssueTemplate.dropdown_names(ref_project)
  end

  def selected_template(issuable)
    params[:issuable_template] if issuable_templates(issuable).any?{ |template| template[:name] == params[:issuable_template] }
  end

  def issuable_todo_button_data(issuable, todo, is_collapsed)
    {
      todo_text: "Add todo",
      mark_text: "Mark done",
      todo_icon: (is_collapsed ? icon('plus-square') : nil),
      mark_icon: (is_collapsed ? icon('check-square', class: 'todo-undone') : nil),
      issuable_id: issuable.id,
      issuable_type: issuable.class.name.underscore,
      url: project_todos_path(@project),
      delete_path: (dashboard_todo_path(todo) if todo),
      placement: (is_collapsed ? 'left' : nil),
      container: (is_collapsed ? 'body' : nil)
    }
  end

  def close_reopen_params(issuable, action)
    {
      issuable.model_name.to_s.underscore => { state_event: action }
    }.tap do |params|
      params[:format] = :json if issuable.is_a?(Issue)
    end
  end
end
