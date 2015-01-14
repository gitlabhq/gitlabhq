module SelectsHelper
  def users_select_tag(id, opts = {})
    css_class = "ajax-users-select "
    css_class << "multiselect " if opts[:multiple]
    css_class << "skip_ldap " if opts[:skip_ldap]
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

  def ldap_server_select_options
    options_from_collection_for_select(
      Gitlab::LDAP::Config.servers,
      'provider_name',
      'label'
    )
  end

  def groups_select_tag(id, opts = {})
    css_class = "ajax-groups-select "
    css_class << "multiselect " if opts[:multiple]
    css_class << (opts[:class] || '')
    value = opts[:selected] || ''

    hidden_field_tag(id, value, class: css_class)
  end

  def admin_email_select_tag(id, opts = {})
    css_class = "ajax-admin-email-select "
    css_class << "multiselect " if opts[:multiple]
    css_class << (opts[:class] || '')
    value = opts[:selected] || ''

    hidden_field_tag(id, value, class: css_class)
  end
end
