module AuditLogsHelper
  def event_type_options
    [
      { id: '', text: 'All Events' },
      { id: 'Group', text: 'Group Events' },
      { id: 'Project', text: 'Project Events' },
      { id: 'User', text: 'User Events' }
    ]
  end

  def admin_user_dropdown_label(default_label)
    if @entity
      @entity.name
    else
      default_label
    end
  end

  def admin_project_dropdown_label(default_label)
    if @entity
      @entity.full_name
    else
      default_label
    end
  end

  def admin_namespace_dropdown_label(default_label)
    if @entity
      @entity.full_path
    else
      default_label
    end
  end
end
