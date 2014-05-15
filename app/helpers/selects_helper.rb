module SelectsHelper
  def users_select_tag(id, opts = {})
    css_class = "ajax-users-select "
    css_class << "multiselect " if opts[:multiple]
    css_class << (opts[:class] || '')
    value = opts[:selected] || ''

    hidden_field_tag(id, value, class: css_class)
  end

  def project_users_select_tag(id, opts = {})
    css_class = "ajax-project-users-select "
    css_class << "multiselect " if opts[:multiple]
    css_class << (opts[:class] || '')
    value = opts[:selected] || ''
    placeholder = opts[:placeholder] || 'Select user'
    project_id = opts[:project_id] || @project.id
    hidden_field_tag(id, value, class: css_class, 'data-placeholder' => placeholder, 'data-project-id' => project_id)
  end
end
