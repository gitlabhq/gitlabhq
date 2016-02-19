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

  private

  def sidebar_gutter_collapsed?
    cookies[:collapsed_gutter] == 'true'
  end

  def base_issuable_scope(issuable)
    issuable.project.send(issuable.class.table_name).send(issuable_state_scope(issuable))
  end

  def issuable_state_scope(issuable)
    issuable.open? ? :opened : :closed
  end

end
