module SelectsHelper
  def users_select_tag(id, opts = {})
    css_class = "ajax-users-select "
    css_class << "multiselect " if opts[:multiple]
    css_class << "skip_ldap " if opts[:skip_ldap]
    css_class << (opts[:class] || '')
    value = opts[:selected] || ''
    placeholder = opts[:placeholder] || 'Search for a user'

    null_user = opts[:null_user] || false
    any_user = opts[:any_user] || false
    email_user = opts[:email_user] || false
    first_user = opts[:first_user] && current_user ? current_user.username : false
    current_user = opts[:current_user] || false
    project = opts[:project] || @project
    push_code_to_protected_branches = opts[:push_code_to_protected_branches]

    html = {
      class: css_class,
<<<<<<< HEAD
      data: {
        placeholder: placeholder,
        null_user: null_user,
        any_user: any_user,
        email_user: email_user,
        first_user: first_user,
        current_user: current_user
      }
=======
      'data-placeholder' => placeholder,
      'data-null-user' => null_user,
      'data-any-user' => any_user,
      'data-email-user' => email_user,
      'data-first-user' => first_user,
<<<<<<< HEAD
      'data-current-user' => current_user
>>>>>>> origin/7-14-stable
=======
      'data-current-user' => current_user,
      'data-push-code-to-protected-branches' => push_code_to_protected_branches
>>>>>>> gitlabhq/ce_upstream
    }

    unless opts[:scope] == :all
      if project
        html['data-project-id'] = project.id
      elsif @group
        html['data-group-id'] = @group.id
      end
    end

    hidden_field_tag(id, value, html)
  end

  def ldap_server_select_options
    options_from_collection_for_select(
      Gitlab::LDAP::Config.servers,
      'provider_name',
      'label'
    )
  end

  def groups_select_tag(id, opts = {})
    opts[:class] ||= ''
    opts[:class] << ' ajax-groups-select'
    select2_tag(id, opts)
  end

  def namespace_select_tag(id, opts = {})
    opts[:class] ||= ''
    opts[:class] << ' ajax-namespace-select'
    select2_tag(id, opts)
  end

  def project_select_tag(id, opts = {})
    opts[:class] ||= ''
    opts[:class] << ' ajax-project-select'

    unless opts.delete(:scope) == :all
      if @group
        opts['data-group-id'] = @group.id
      end
    end

    hidden_field_tag(id, opts[:selected], opts)
  end

  def select2_tag(id, opts = {})
    css_class = ''
    css_class << 'multiselect ' if opts[:multiple]
    css_class << (opts[:class] || '')
    value = opts[:selected] || ''

    hidden_field_tag(id, value, class: css_class, data: { skip_group: opts[:skip_group], url: autocomplete_groups_path })
  end

  def admin_email_select_tag(id, opts = {})
    css_class = "ajax-admin-email-select "
    css_class << "multiselect " if opts[:multiple]
    css_class << (opts[:class] || '')
    value = opts[:selected] || ''

    hidden_field_tag(id, value, class: css_class)
  end
end
