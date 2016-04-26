module IssuablesHelper

  def sidebar_gutter_toggle_icon
    sidebar_gutter_collapsed? ? icon('angle-double-left') : icon('angle-double-right')
  end

  def sidebar_gutter_collapsed_class
    "right-sidebar-#{sidebar_gutter_collapsed? ? 'collapsed' : 'expanded'}"
  end

  def issuables_count(issuable)
    base_issuable_scope(issuable).maximum(:iid)
  end

  def next_issuable_for(issuable)
    base_issuable_scope(issuable).where('iid > ?', issuable.iid).last
  end

  def multi_label_name(current_labels, default_label)
    # current_labels may be a string from before
    if current_labels.is_a?(Array)
      if current_labels.count > 1
        "#{current_labels[0]} +#{current_labels.count - 1} more"
      else
        current_labels[0]
      end
    elsif current_labels.is_a?(String)
      if current_labels.nil? || current_labels.empty?
        default_label
      else
        current_labels
      end
    else
      default_label
    end
  end

  def issuable_json_path(issuable)
    project = issuable.project

    if issuable.kind_of?(MergeRequest)
      namespace_project_merge_request_path(project.namespace, project, issuable.iid, :json)
    else
      namespace_project_issue_path(project.namespace, project, issuable.iid, :json)
    end
  end

  def prev_issuable_for(issuable)
    base_issuable_scope(issuable).where('iid < ?', issuable.iid).first
  end

  def user_dropdown_label(user_id, default_label)
    return "Unassigned" if user_id == "0"

    if @project
      member = @project.team.find_member(user_id)
      user = member.user if member
    else
      user = User.find_by(id: user_id)
    end

    if user
      user.name
    else
      default_label
    end
  end

  def milestone_dropdown_label(milestone_title, default_label = "Milestone")
    if milestone_title == Milestone::Upcoming.name
      milestone_title = Milestone::Upcoming.title
    end

    h(milestone_title.presence || default_label)
  end

  def issuable_meta(issuable, project, text)
    output = content_tag :strong, "#{text} #{issuable.to_reference}", class: "identifier"
    output << " opened #{time_ago_with_tooltip(issuable.created_at)} by".html_safe
    output << content_tag(:strong) do
      author_output = link_to_member(project, issuable.author, size: 24, mobile_classes: "hidden-xs")
      author_output << link_to_member(project, issuable.author, size: 24, by_username: true, avatar: false, mobile_classes: "hidden-sm hidden-md hidden-lg")
    end
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

end
