module SelectsHelper
  def users_select_tag(id, opts = {})
    css_class = "ajax-users-select "
    css_class << "multiselect " if opts[:multiple]
    css_class << (opts[:class] || '')
    value = opts[:selected] || ''
    placeholder = opts[:placeholder] || 'Search for a user'

    null_user = opts[:null_user] || false
    any_user = opts[:any_user] || false
    email_user = opts[:email_user] || false
    first_user = opts[:first_user] && current_user ? current_user.username : false
    current_user = opts[:current_user] || false
    project = opts[:project] || @project

    html = {
      class: css_class,
      'data-placeholder' => placeholder,
      'data-null-user' => null_user,
      'data-any-user' => any_user,
      'data-email-user' => email_user,
      'data-first-user' => first_user,
      'data-current-user' => current_user
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

  def groups_select_tag(id, opts = {})
    css_class = "ajax-groups-select "
    css_class << "multiselect " if opts[:multiple]
    css_class << (opts[:class] || '')
    value = opts[:selected] || ''

    hidden_field_tag(id, value, class: css_class)
  end
end
