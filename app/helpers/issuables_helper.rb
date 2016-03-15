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

  def prev_issuable_for(issuable)
    base_issuable_scope(issuable).where('iid < ?', issuable.iid).first
  end

  def user_dropdown_label(user_id, default_label)
    return "Unassigned" if user_id == "0"

    user = @project.team.users.find_by(id: user_id) if @project
    user = User.find_by_id(user_id) if !@project

    if user
      user.name
    else
      default_label
    end
  end

  def labels_dropdown_label(label_name)
    if !label_name
      "Label"
    else
      label_name
    end
  end

  def milestone_dropdown_label(milestone_name)
    if !milestone_name
      "Milestone"
    else
      milestone_name
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
